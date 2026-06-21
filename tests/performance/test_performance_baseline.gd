extends GdUnitTestSuite


func test_node_count_budget() -> void:
	var helper := PerformanceTestHelper.new()
	var budget := PerformanceTestHelper.make_budget({"NODES": 100})
	helper.assert_below(budget)


func test_draw_calls_budget() -> void:
	var helper := PerformanceTestHelper.new()
	var budget := PerformanceTestHelper.make_budget({"DRAW_CALLS": 200})
	helper.assert_below(budget)
