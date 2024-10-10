#include <Light3D.cuh>

void Light3D::demo(Render3D *render) {
    const size_t block_size = 256;
    const size_t block_count = (render->BUFFER_SIZE + block_size - 1) / block_size;

    lightingKernel<<<block_count, block_size>>>(
        render->D_BUFFER, *this, render->BUFFER_SIZE
    );
    CUDA_CHECK(cudaDeviceSynchronize());

    render->bufferMemcpy();
}

// Kernel for applying lighting
__global__ void lightingKernel(
    Pixel3D *pixels, Light3D light, int size
) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= size) return;

    Color3D color = pixels[i].color;

    Vec3D lightDir = Vec3D::sub(light.pos, pixels[i].world);
    double cosA = Vec3D::dot(pixels[i].normal, lightDir) /
        (Vec3D::mag(pixels[i].normal) * Vec3D::mag(lightDir));

    if (cosA < 0) cosA = 0;

    double ratio = light.ambient + cosA * (light.specular - light.ambient);

    color.runtimeRGB.mult(ratio);

    // Apply colored light
    color.runtimeRGB.v1 = color.runtimeRGB.v1 * light.rgbRatio.x;
    color.runtimeRGB.v2 = color.runtimeRGB.v2 * light.rgbRatio.y;
    color.runtimeRGB.v3 = color.runtimeRGB.v3 * light.rgbRatio.z;

    // Restrict color values
    color.runtimeRGB.restrictRGB();

    pixels[i].color = color;
}