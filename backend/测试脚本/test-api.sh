#!/bin/bash

# ===========================================
# 微运动API测试脚本
# 测试DeepSeek API集成是否正常工作
# ===========================================

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 配置
API_BASE="http://localhost:8080/api/micro-motion"
TIMEOUT=30

# 打印带颜色的信息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_separator() {
    echo "=========================================="
}

# 检查服务是否可用
check_health() {
    print_info "检查服务健康状态..."
    response=$(curl -s -o /dev/null -w "%{http_code}" --max-time $TIMEOUT $API_BASE/health)

    if [ "$response" = "200" ]; then
        print_success "服务运行正常"
        return 0
    else
        print_error "服务不可用 (HTTP $response)"
        print_warning "请确保后端服务已启动 (端口: 8080)"
        return 1
    fi
}

# 测试生成提示词
test_generate_prompt() {
    local test_name=$1
    local data=$2

    print_separator
    print_info "测试: $test_name"
    print_separator

    # 发送请求
    response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$data" \
        --max-time $TIMEOUT \
        $API_BASE/generate-prompt)

    # 检查curl是否成功
    if [ $? -ne 0 ]; then
        print_error "请求失败，请检查网络连接"
        return 1
    fi

    # 检查响应是否为空
    if [ -z "$response" ]; then
        print_error "响应为空"
        return 1
    fi

    # 尝试解析JSON并提取信息
    status=$(echo "$response" | grep -o '"status":"[^"]*"' | cut -d':' -f2 | tr -d '"')
    error_msg=$(echo "$response" | grep -o '"error_message":"[^"]*"' | cut -d':' -f2 | tr -d '"')

    if [ "$status" = "success" ]; then
        print_success "生成成功！"

        # 提取提示词内容
        prompt_text=$(echo "$response" | grep -o '"prompt_text":"[^"]*"' | cut -d':' -f2 | tr -d '"' | sed 's/\\n/\n/g')
        duration=$(echo "$response" | grep -o '"suggested_duration":[0-9]*' | cut -d':' -f2)
        difficulty=$(echo "$response" | grep -o '"difficulty_level":"[^"]*"' | cut -d':' -f2 | tr -d '"')

        echo -e "\n${GREEN}生成的提示词:${NC}"
        echo "------------------------------------------"
        echo -e "$prompt_text" | sed 's/\\n/\n/g' | sed 's/\\//g'
        echo "------------------------------------------"
        echo -e "建议时长: ${YELLOW}${duration}秒${NC}"
        echo -e "难度级别: ${YELLOW}${difficulty}${NC}"

        # 显示token使用情况
        prompt_tokens=$(echo "$response" | grep -o '"prompt_tokens":[0-9]*' | cut -d':' -f2)
        completion_tokens=$(echo "$response" | grep -o '"completion_tokens":[0-9]*' | cut -d':' -f2)
        total_tokens=$(echo "$response" | grep -o '"total_tokens":[0-9]*' | cut -d':' -f2)

        if [ ! -z "$total_tokens" ]; then
            echo -e "Token使用: ${BLUE}提示: $prompt_tokens, 生成: $completion_tokens, 总计: $total_tokens${NC}"
        fi

    else
        print_error "生成失败"
        if [ ! -z "$error_msg" ]; then
            echo -e "错误信息: ${RED}$error_msg${NC}"
        else
            echo -e "原始响应: $response"
        fi
    fi
}

# 测试不同场景
run_all_tests() {
    print_info "开始API测试..."
    echo ""

    # 先检查健康状态
    check_health
    if [ $? -ne 0 ]; then
        print_error "服务未启动，请先启动后端服务"
        print_warning "启动命令: cd backend && mvn spring-boot:run"
        exit 1
    fi

    # 测试1: 颈部问题（年轻人）
    test_generate_prompt "颈部问题 - 年轻人" '{
        "body_part": "颈部",
        "posture_info": "长时间低头看手机，坐姿不正确，感觉颈部僵硬",
        "user_info": {
            "age": 25,
            "gender": "男",
            "height": 175,
            "weight": 70,
            "bmi": 22.9,
            "bmi_type": "正常"
        }
    }'

    echo -e "\n\n"
    sleep 2  # 等待2秒再测下一个

    # 测试2: 腰部问题（中年人，偏胖）
    test_generate_prompt "腰部问题 - 中年人偏胖" '{
        "body_part": "腰部",
        "posture_info": "久坐办公，腰部酸疼，起身时感觉僵硬",
        "user_info": {
            "age": 45,
            "gender": "男",
            "height": 170,
            "weight": 80,
            "bmi": 27.7,
            "bmi_type": "偏胖"
        }
    }'

    echo -e "\n\n"
    sleep 2

    # 测试3: 肩部问题（女性，正常）
    test_generate_prompt "肩部问题 - 女性正常" '{
        "body_part": "肩部",
        "posture_info": "圆肩驼背，长时间用电脑，肩膀酸痛",
        "user_info": {
            "age": 32,
            "gender": "女",
            "height": 165,
            "weight": 55,
            "bmi": 20.2,
            "bmi_type": "正常"
        }
    }'

    echo -e "\n\n"
    sleep 2

    # 测试4: 眼部问题（特殊测试）
    test_generate_prompt "眼部问题 - 老年人" '{
        "body_part": "眼睛",
        "posture_info": "长时间看屏幕，眼睛干涩疲劳",
        "user_info": {
            "age": 55,
            "gender": "女",
            "height": 160,
            "weight": 60,
            "bmi": 23.4,
            "bmi_type": "正常"
        }
    }'

    echo -e "\n\n"
    sleep 2

    # 测试5: 手腕问题
    test_generate_prompt "手腕问题 - 程序员" '{
        "body_part": "手腕",
        "posture_info": "长时间打字，手腕酸痛",
        "user_info": {
            "age": 28,
            "gender": "男",
            "height": 180,
            "weight": 75,
            "bmi": 23.1,
            "bmi_type": "正常",
            "occupation": "程序员"
        }
    }'

    echo -e "\n\n"
    print_separator
    print_success "所有测试完成！"
    print_separator
}

# 显示帮助信息
show_help() {
    echo "用法: ./test-api.sh [选项]"
    echo "选项:"
    echo "  all       运行所有测试（默认）"
    echo "  health    只检查健康状态"
    echo "  neck      只测试颈部"
    echo "  waist     只测试腰部"
    echo "  shoulder  只测试肩部"
    echo "  eye       只测试眼睛"
    echo "  wrist     只测试手腕"
    echo "  help      显示此帮助信息"
}

# 主函数
main() {
    case "$1" in
        "health")
            check_health
            ;;
        "neck")
            check_health && test_generate_prompt "颈部单独测试" '{
                "body_part": "颈部",
                "posture_info": "长时间低头，颈部不适",
                "user_info": {"age": 30, "gender": "男", "bmi": 23}
            }'
            ;;
        "waist")
            check_health && test_generate_prompt "腰部单独测试" '{
                "body_part": "腰部",
                "posture_info": "久坐，腰部酸痛",
                "user_info": {"age": 35, "gender": "女", "bmi": 24}
            }'
            ;;
        "shoulder")
            check_health && test_generate_prompt "肩部单独测试" '{
                "body_part": "肩部",
                "posture_info": "圆肩驼背，肩膀紧张",
                "user_info": {"age": 28, "gender": "男", "bmi": 22}
            }'
            ;;
        "eye")
            check_health && test_generate_prompt "眼部单独测试" '{
                "body_part": "眼睛",
                "posture_info": "眼睛疲劳，干涩",
                "user_info": {"age": 40, "gender": "女", "bmi": 23}
            }'
            ;;
        "wrist")
            check_health && test_generate_prompt "手腕单独测试" '{
                "body_part": "手腕",
                "posture_info": "长时间打字，手腕酸痛",
                "user_info": {"age": 32, "gender": "男", "bmi": 24}
            }'
            ;;
        "help")
            show_help
            ;;
        *)
            run_all_tests
            ;;
    esac
}

# 执行主函数
main $1