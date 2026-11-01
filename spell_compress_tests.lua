local comp_utils = require("core.spell_compress_utils")

print(comp_utils.compress({"A", "B", "A"}))
print(comp_utils.compress({"LIGHT_SHOT", "LIGHT_SHOT", "LIGHT_BULLET", "LIGHT_BULLET"}))
