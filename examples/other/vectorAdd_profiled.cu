/**
 * Derived from the nVIDIA CUDA 8.0 samples by
 *
 *   Eyal Rozenberg
 *
 * The derivation is specifically permitted in the nVIDIA CUDA Samples EULA
 * and the deriver is the owner of this code according to the EULA.
 *
 * Use this reasonably. If you want to discuss licensing formalities, please
 * contact the author.
 */

#include "../common.hpp"

#include <cuda/api.hpp>
#include <cuda/nvtx.hpp>

#include <iostream>
#include <memory>
#include <algorithm>

__global__ void vectorAdd(const float *A, const float *B, float *C, int numElements)
{
	int i = blockDim.x * blockIdx.x + threadIdx.x;
	if (i < numElements) { C[i] = A[i] + B[i]; }
}

int main()
{
	profile_this_scope();
	cuda::profiling::name_this_thread("The single thread for vectorAdd_profile :-)");
	if (cuda::device::count() == 0) {
		::std::cerr << "No CUDA devices on this system" << "\n";
		exit(EXIT_FAILURE);
	}

	int numElements = 500000;
	size_t size = numElements * sizeof(float);

	// If we could rely on C++14, we would  use ::std::make_unique
	auto h_A = ::std::unique_ptr<float>(new float[numElements]);
	auto h_B = ::std::unique_ptr<float>(new float[numElements]);
	auto h_C = ::std::unique_ptr<float>(new float[numElements]);

	auto generator = []() { return rand() / (float) RAND_MAX; };
	::std::generate(h_A.get(), h_A.get() + numElements, generator);
	::std::generate(h_B.get(), h_B.get() + numElements, generator);

	auto device = cuda::device::current::get();
	auto d_A = cuda::memory::device::make_unique<float[]>(device, numElements);
	auto d_B = cuda::memory::device::make_unique<float[]>(device, numElements);
	auto d_C = cuda::memory::device::make_unique<float[]>(device, numElements);

	cuda::memory::copy(d_A.get(), h_A.get(), size);
	cuda::memory::copy(d_B.get(), h_B.get(), size);

	// Launch the Vector Add CUDA Kernel
	int threadsPerBlock = 256;
	int blocksPerGrid = (numElements + threadsPerBlock - 1) / threadsPerBlock;
	::std::cout
		<< "CUDA kernel launch with " << blocksPerGrid
		<< " blocks of " << threadsPerBlock << " threads\n";

	cuda::launch(vectorAdd,
		cuda::make_launch_config( blocksPerGrid, threadsPerBlock ),
		d_A.get(), d_B.get(), d_C.get(), numElements
	);

	cuda::memory::copy(h_C.get(), d_C.get(), size);

	::std::cout << "SUCCESS\n";
}

