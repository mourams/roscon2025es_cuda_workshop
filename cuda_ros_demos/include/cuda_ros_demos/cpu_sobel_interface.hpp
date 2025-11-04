#pragma once
#include <opencv2/opencv.hpp>

void sobelCPU(const cv::Mat& gray, cv::Mat& edges, float threshold=50.0f);

