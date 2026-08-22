class_name AttributeDefinition
extends Resource
# Define um atributo genérico. Você cria tantos quanto quiser em data/stats/*.tres.
# Exemplos: hp, armor, shield, mana, willpower, stamina, movimento...

@export var id: String = "" # ex: "hp"
@export var nome: String = "" # ex: "Vida"
@export var default_value: int = 10
@export var min_value: int = 0
@export var max_value: int = 999
@export var is_resource: bool = false # true = custo (mana/willpower), false = stat base (hp/armor)
@export var descricao: String = ""
