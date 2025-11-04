#include "cuda_ros_demos/cuda_sobel_interface.cuh" // Interfaz CUDA

#include <rclcpp/rclcpp.hpp>
#include <sensor_msgs/msg/image.hpp>
#include <cv_bridge/cv_bridge.h>
#include <opencv2/opencv.hpp>

class CudaSobelNode : public rclcpp::Node
{
public:
    CudaSobelNode() : Node("cuda_sobel_node")
    {
        this->declare_parameter<double>("edge_threshold", 50.0);
        this->get_parameter("edge_threshold", edge_threshold_);

        sub_ = this->create_subscription<sensor_msgs::msg::Image>("/camera/image_raw", 10,
                                                                  std::bind(&CudaSobelNode::imageCallback, this, std::placeholders::_1));
        pub_ = this->create_publisher<sensor_msgs::msg::Image>("/camera/image_edges", 10);

        param_cb_ = this->add_on_set_parameters_callback(
            std::bind(&CudaSobelNode::onParameterChanged, this, std::placeholders::_1));

        RCLCPP_INFO(this->get_logger(), "Nodo CudaSobelNode inicializado");
    }

private:
    void imageCallback(const sensor_msgs::msg::Image::SharedPtr msg)
    {
        try
        {
            auto start = std::chrono::steady_clock::now();

            // Conversión a formato OpenCV
            cv::Mat rgb = cv_bridge::toCvShare(msg, "bgr8")->image;

            // Conversión a imagen gris
            cv::Mat gray;
            cv::cvtColor(rgb, gray, cv::COLOR_BGR2GRAY);

            // Alocar o reutilizar imagen de bordes
            if (edges_.empty() || edges_.size() != gray.size())
            {
                edges_ = cv::Mat(gray.rows, gray.cols, CV_8UC1);
            }

            // Ejecutar Sobel en GPU
            runCudaSobel(gray, edges_, edge_threshold_);

            // Crear imagen de salida con bordes resaltados
            cv::Mat overlay = rgb.clone();
            overlay.setTo(cv::Scalar(0, 0, 255), edges_); // Bordes rojos

            // Convertir a mensaje ROS
            auto out_msg = cv_bridge::CvImage(msg->header, "bgr8", overlay).toImageMsg();

            // Medir tiempo de procesamiento
            auto end = std::chrono::steady_clock::now();
            double dur = std::chrono::duration<double, std::milli>(end - start).count();
            RCLCPP_INFO(this->get_logger(), "Tiempo de procesamiento: %.3f ms", dur);

            // Publicar imagen procesada
            pub_->publish(*out_msg);
        }
        catch (const cv_bridge::Exception &e)
        {
            RCLCPP_ERROR(this->get_logger(), "Error cv_bridge: %s", e.what());
        }
    }

    rcl_interfaces::msg::SetParametersResult onParameterChanged(const std::vector<rclcpp::Parameter> &params)
    {
        rcl_interfaces::msg::SetParametersResult result;
        result.successful = true;
        result.reason = "";

        for (const auto &param : params)
        {
            if (param.get_name() == "edge_threshold")
            {
                edge_threshold_ = param.as_double();
                RCLCPP_INFO(this->get_logger(), "Umbral de detección actualizado a %.1f", edge_threshold_);
            }
        }
        return result;
    }

    rclcpp::Subscription<sensor_msgs::msg::Image>::SharedPtr sub_;
    rclcpp::Publisher<sensor_msgs::msg::Image>::SharedPtr pub_;
    rclcpp::node_interfaces::OnSetParametersCallbackHandle::SharedPtr param_cb_;

    cv::Mat edges_;
    double edge_threshold_;
};

int main(int argc, char **argv)
{
    rclcpp::init(argc, argv);
    rclcpp::spin(std::make_shared<CudaSobelNode>());
    rclcpp::shutdown();
    return 0;
}
