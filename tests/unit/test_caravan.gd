extends GutTest
# Testa CaravanManager — garante que economia de supplies/morale não quebrou.


func test_consume_day() -> void:
	var c := CaravanManager.new()
	add_child_autofree(c)
	c.supplies = 10
	c.morale = 50
	c.consume_day()
	assert_eq(c.supplies, 9)
	assert_eq(c.morale, 40)
	assert_eq(c.day, 2)


func test_rest_day_recovers_morale() -> void:
	var c := CaravanManager.new()
	add_child_autofree(c)
	c.supplies = 10
	c.morale = 40
	c.rest_day()
	assert_eq(c.morale, 50)
	assert_eq(c.supplies, 9)


func test_rest_without_supplies_no_morale() -> void:
	var c := CaravanManager.new()
	add_child_autofree(c)
	c.supplies = 0
	c.morale = 40
	c.rest_day()
	assert_eq(c.morale, 40, "Sem supplies não recupera morale")


func test_morale_state() -> void:
	var c := CaravanManager.new()
	add_child_autofree(c)
	c.morale = 10
	assert_eq(c.get_morale_state(), "miserable")
	c.morale = 90
	assert_eq(c.get_morale_state(), "great")
