# lockcore/tiers.json is the checked-in copy of every family's tier range, read by tools that
# do not link lockcore (data/tools/validate.py, D-118). It must equal `verify_seeds --tiers`.
# Regenerate: lockcore/build/verify_seeds --tiers > lockcore/tiers.json
execute_process(COMMAND ${TOOL} --tiers OUTPUT_VARIABLE live RESULT_VARIABLE rc)
if(NOT rc EQUAL 0)
  message(FATAL_ERROR "verify_seeds --tiers failed (${rc})")
endif()
file(READ ${FILE} stored)
string(REPLACE "\r\n" "\n" stored "${stored}")
if(NOT live STREQUAL stored)
  message(FATAL_ERROR "lockcore/tiers.json is out of date; run: lockcore/build/verify_seeds --tiers > lockcore/tiers.json\n--- live ---\n${live}")
endif()
