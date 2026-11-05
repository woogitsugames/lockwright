# Copies a golden replay with expected.steps changed by one; `replay_tool play`
# must then fail although the event hash still matches (T25-09).
file(READ ${IN} text)
string(REGEX MATCH "\"steps\": ([0-9]+)" m "${text}")
math(EXPR wrong "${CMAKE_MATCH_1} + 1")
string(REPLACE "\"steps\": ${CMAKE_MATCH_1}" "\"steps\": ${wrong}" text "${text}")
file(WRITE ${OUT} "${text}")
execute_process(COMMAND ${TOOL} play ${OUT} RESULT_VARIABLE rc OUTPUT_VARIABLE out ERROR_VARIABLE err)
if(rc EQUAL 0)
  message(FATAL_ERROR "play accepted a wrong expected.steps: ${out}")
endif()
if(NOT out MATCHES "steps [0-9]+ != expected")
  message(FATAL_ERROR "play did not name the mismatching field: ${out}${err}")
endif()
