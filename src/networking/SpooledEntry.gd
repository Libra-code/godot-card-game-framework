class_name SpooledEntry
extends Reference

const card_index_manipulations = [
	"card_index_changed",
	"card_moved_to_board",
	"card_moved_to_pile",
	"card_moved_to_hand",
]

var card: Card
var manipulations: Array

func _init(_card: Card, type: String) -> void:
	card = _card
	manipulations.append(type)

func add_manipulation(type: String) -> void:
	if not type in manipulations:
		manipulations.append(type)

func is_container_manipulated(checked_card: Card) -> bool:
	if card.get_parent() == checked_card.get_parent()\
			and is_index_manipulation():
				return(true)
	return(false)

func unspool() -> void:
	card.set_current_manipulation(Card.StateManipulation.NONE)

func get_payload(existing_payload := {}, container_node_map := {}) -> Dictionary:
	var payload := existing_payload.duplicate(true)
	for type in manipulations:
		match type: 
			"card_index_changed",\
					"card_moved_to_board",\
					"card_board_position_changed",\
					"card_moved_to_pile",\
					"card_moved_to_hand":
				var positional_payload := get_positional_payload(
						card, container_node_map)
				payload["pos_x"] = positional_payload["pos_x"]
				payload["pos_y"] = positional_payload["pos_y"]
				payload["board_grid_slot"] = positional_payload["board_grid_slot"]
				payload["node_index"] = positional_payload["node_index"]
				payload["container"] = positional_payload["container"]
			"card_rotated":
				payload["rotation"] = card.card_rotation
			"card_flipped":
				payload["is_faceup"] = card.is_faceup
			"card_viewed":
				pass
			"card_token_modified":
				payload["tokens"] = _gather_tokens_payload(card)
			"card_attached", "card_unattached":
				pass
			"card_properties_modified":
				payload["properties"] = card.properties
				payload["card_name"] = card.canonical_name
	return(payload)

func is_index_manipulation() -> bool:
	for manipulation_type in manipulations:
		if manipulation_type in card_index_manipulations:
			return(true)
	return(false)

static func get_positional_payload(card: Card, container_node_map: Dictionary) -> Dictionary:
	var payload: Dictionary
	payload["pos_x"] = card.position.x
	payload["pos_y"] = card.position.y	
	var card_parent = discover_card_container(card)
	if card_parent:
		payload["container"] = container_node_map[card_parent]
		var board_grid_slot = null
		if card._placement_slot:
			board_grid_slot = [
					card._placement_slot.get_grid_name(),
					card._placement_slot.get_index()
			]
		payload["board_grid_slot"] = board_grid_slot
		payload["node_index"] = card.get_my_card_index()
	return(payload)
				
static func discover_card_container(card: Card) -> Node:
	var card_parent = card.get_parent()
	if card_parent and is_instance_valid(card_parent):
		if "CardPopUpSlot" in card_parent.name:
			card_parent = card_parent.get_parent().get_parent().get_parent()
	else:
		card_parent = null
	return(card_parent)				


func _gather_tokens_payload(card: Card) -> Dictionary:
	var token_payload := {}
	var all_tokens := card.tokens.get_all_tokens()
	for token_name in all_tokens:
		token_payload[token_name] = all_tokens[token_name].get_unaltered_count()
	return(token_payload)
