extends Node

func generate_report() -> Dictionary:
	if GameState.skill >= 35 and GameState.mood >= 40:
		return {
			"title": "还没有上岸，但开始有方向",
			"keyword": "你还没抵达，但已经开始走了。"
		}
	if GameState.money < 1000:
		return {
			"title": "钱开始变紧，但你还在坚持",
			"keyword": "生活没有给你太多余地，但你还没有放弃。"
		}
	if GameState.relationship >= 60:
		return {
			"title": "至少你还没有和重要的人走散",
			"keyword": "长大不是一个人消失，而是学会认真告别。"
		}
	if GameState.pressure >= 70:
		return {
			"title": "你太累了，需要停下来喘口气",
			"keyword": "不是你不够努力，是你已经撑了很久。"
		}
	return {
		"title": "未来还没确定，但你已经走过了第一周",
		"keyword": "第 100 天还很远，但第 1 周已经过去了。"
	}
