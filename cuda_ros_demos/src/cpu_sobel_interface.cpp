#include "cuda_ros_demos/cpu_sobel_interface.hpp"
#include <cmath>
#include <algorithm>

// Sobel kernels
const int Gx[3][3] = {
    {-1, 0, 1},
    {-2, 0, 2},
    {-1, 0, 1}
};

const int Gy[3][3] = {
    {-1, -2, -1},
    { 0,  0,  0},
    { 1,  2,  1}
};

constexpr float MAX_SOBEL_MAG = 1020.0f;

void sobelCPU(const cv::Mat& gray, cv::Mat& edges, float threshold)
{
    int width = gray.cols;
    int height = gray.rows;
    edges.create(height, width, CV_8UC1);

    for(int y=0; y<height; y++)
    {
        for(int x=0; x<width; x++)
        {
            float sumX = 0.0f;
            float sumY = 0.0f;

            for(int ky=-1; ky<=1; ky++)
            {
                for(int kx=-1; kx<=1; kx++)
                {
                    int ix = std::min(std::max(x + kx, 0), width-1);
                    int iy = std::min(std::max(y + ky, 0), height-1);
                    float pixel = static_cast<float>(gray.at<unsigned char>(iy, ix));
                    sumX += pixel * Gx[ky+1][kx+1];
                    sumY += pixel * Gy[ky+1][kx+1];
                }
            }

            float mag = std::sqrt(sumX*sumX + sumY*sumY);
            float scaled = (mag / MAX_SOBEL_MAG) * 255.0f;
            edges.at<unsigned char>(y, x) = (scaled >= threshold) ? 255 : 0;
        }
    }
}
