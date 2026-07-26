package deepseek

import (
	"context"
	"encoding/binary"
	"fmt"
	"math"
	"os"


	"github.com/tetratelabs/wazero"
	"github.com/tetratelabs/wazero/imports/wasi_snapshot_preview1"
)


type WASMSolver struct {
	runtime   wazero.Runtime
	module    wazero.CompiledModule
	wasmBytes []byte
}

func NewWASMSolver(wasmPath string) (*WASMSolver, error) {
	wasmBytes, err := os.ReadFile(wasmPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read wasm file: %w", err)
	}

	return &WASMSolver{
		wasmBytes: wasmBytes,
	}, nil
}

func (w *WASMSolver) Init(ctx context.Context) error {
	w.runtime = wazero.NewRuntime(ctx)
	wasi_snapshot_preview1.MustInstantiate(ctx, w.runtime)

	module, err := w.runtime.CompileModule(ctx, w.wasmBytes)
	if err != nil {
		return fmt.Errorf("failed to compile wasm: %w", err)
	}
	w.module = module

	return nil
}

func (w *WASMSolver) Solve(ctx context.Context, challenge *Challenge) (int, error) {
	if w.module == nil {
		return 0, fmt.Errorf("wasm module not initialized")
	}

	config := wazero.NewModuleConfig().
		WithName("pow").
		WithStdout(os.Stdout).
		WithStderr(os.Stderr)

	instance, err := w.runtime.InstantiateModule(ctx, w.module, config)
	if err != nil {
		return 0, fmt.Errorf("failed to instantiate wasm: %w", err)
	}
	defer instance.Close(ctx)

	alloc := instance.ExportedFunction("__wbindgen_export_0")
	stackPointerFunc := instance.ExportedFunction("__wbindgen_add_to_stack_pointer")
	wasmSolve := instance.ExportedFunction("wasm_solve")

	memory := instance.Memory()
	if memory == nil {
		return 0, fmt.Errorf("memory not exported")
	}

	nStr := fmt.Sprintf("%s_%d_", challenge.Salt, challenge.ExpireAt)
	challengeBytes := []byte(challenge.Challenge)
	nBytes := []byte(nStr)

	allocResults, err := alloc.Call(ctx, uint64(len(challengeBytes)), uint64(1))
	if err != nil || len(allocResults) != 1 {
		return 0, fmt.Errorf("failed to allocate challenge memory")
	}
	challengePtr := uint32(allocResults[0])

	allocResults, err = alloc.Call(ctx, uint64(len(nBytes)), uint64(1))
	if err != nil || len(allocResults) != 1 {
		return 0, fmt.Errorf("failed to allocate n memory")
	}
	nPtr := uint32(allocResults[0])

	if !memory.Write(challengePtr, challengeBytes) {
		return 0, fmt.Errorf("failed to write challenge to memory")
	}
	if !memory.Write(nPtr, nBytes) {
		return 0, fmt.Errorf("failed to write n to memory")
	}

	stackResults, err := stackPointerFunc.Call(ctx, uint64(^uint32(16)+1))
	if err != nil || len(stackResults) != 1 {
		return 0, fmt.Errorf("failed to allocate stack")
	}
	stackPtr := uint32(stackResults[0])


	difficulty := float64(challenge.Difficulty)
	difficultyBits := math.Float64bits(difficulty)

	_, err = wasmSolve.Call(ctx,
		uint64(stackPtr),
		uint64(challengePtr),
		uint64(len(challengeBytes)),
		uint64(nPtr),
		uint64(len(nBytes)),
		uint64(difficultyBits),
	)
	if err != nil {
		stackPointerFunc.Call(ctx, uint64(16))
		return 0, fmt.Errorf("failed to call wasm_solve: %w", err)
	}

	resultBytes, ok := memory.Read(stackPtr, 16)
	if !ok {
		stackPointerFunc.Call(ctx, uint64(16))
		return 0, fmt.Errorf("failed to read result from memory")
	}

	status := int32(binary.LittleEndian.Uint32(resultBytes[0:4]))
	answerRaw := math.Float64frombits(binary.LittleEndian.Uint64(resultBytes[8:16]))

	stackPointerFunc.Call(ctx, uint64(16))

	if status == 0 {
		return 0, fmt.Errorf("pow solving failed: status is 0")
	}

	return int(math.Floor(answerRaw)), nil
}

func (w *WASMSolver) Close(ctx context.Context) error {
	if w.runtime != nil {
		return w.runtime.Close(ctx)
	}
	return nil
}
