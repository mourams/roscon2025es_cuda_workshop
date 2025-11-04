#include "cuda_ros_demos/cpu_sobel_interface.hpp"

#include <rclcpp/rclcpp.hpp>
#include <sensor_msgs/msg/image.hpp>
#include <cv_bridge/cv_bridge.h>
#include <opencv2/opencv.hpp>

class CpuSobelNode : public rclcpp::Node
{
public:
    CpuSobelNode() : Node("cpu_sobel_node")
    {
        this->declare_parameter<double>("edge_threshold", 50.0);
        this->get_parameter("edge_threshold", edge_threshold_);

        sub_ = this->create_subscription<sensor_msgs::msg::Image>("/camera/image_raw", 10,
                                                                  std::bind(&CpuSobelNode::imageCallback, this, std::placeholders::_1));
        pub_ = this->create_publisher<sensor_msgs::msg::Image>("/camera/image_edges", 10);

        param_cb_ = this->add_on_set_parameters_callback(
            std::bind(&CpuSobelNode::onParameterChanged, this, std::placeholders::_1));

        RCLCPP_INFO(this->get_logger(), "Nodo CpuSobelNode inicializado");
    }

private:
    void imageCallback(const sensor_msgs::msg::Image::SharedPtr msg)
    {
        try
        {
            auto start = std::chrono::steady_clock::now();

            cv::Mat rgb = cv_bridge::toCvShare(msg, "bgr8")->image;
            cv::Mat gray, edges;

            cv::cvtColor(rgb, gray, cv::COLOR_BGR2GRAY);

            sobelCPU(gray, edges, static_cast<float>(edge_threshold_));

            // Overlay edges in red
            if (overlay_.empty() || overlay_.size() != rgb.size())
                overlay_ = rgb.clone();
            rgb.copyTo(overlay_);
            overlay_.setTo(cv::Scalar(0, 0, 255), edges);

            auto out_msg = cv_bridge::CvImage(msg->header, "bgr8", overlay_).toImageMsg();

            // Medir tiempo de procesamiento
            auto end = std::chrono::steady_clock::now();
            double dur = std::chrono::duration<double, std::milli>(end - start).count();
            RCLCPP_INFO(this->get_logger(), "Tiempo de procesamiento: %.3f ms", dur);

            pub_->publish(*out_msg);
        }
        catch (const cv_bridge::Exception &e)
        {
            RCLCPP_ERROR(this->get_logger(), "cv_bridge exception: %s", e.what());
        }
    }

    rcl_interfaces::msg::SetParametersResult onParameterChanged(
        const std::vector<rclcpp::Parameter> &params)
    {
        rcl_interfaces::msg::SetParametersResult result;
        result.successful = true;
        result.reason = "";

        for (const auto &param : params)
        {
            if (param.get_name() == "edge_threshold")
            {
                edge_threshold_ = param.as_double();
                RCLCPP_INFO(this->get_logger(), "Edge threshold updated to %.1f", edge_threshold_);
            }
        }
        return result;
    }

private:
    rclcpp::Subscription<sensor_msgs::msg::Image>::SharedPtr sub_;
    rclcpp::Publisher<sensor_msgs::msg::Image>::SharedPtr pub_;
    rclcpp::node_interfaces::OnSetParametersCallbackHandle::SharedPtr param_cb_;

    cv::Mat overlay_;
    double edge_threshold_;
};

int main(int argc, char **argv)
{
    rclcpp::init(argc, argv);
    rclcpp::spin(std::make_shared<CpuSobelNode>());
    rclcpp::shutdown();
    return 0;
}
