#!/bin/bash -x

time ./check_export.sh i ../../linux init_list
time ./check_export.sh e ../../linux exit_list
time ./check_export.sh n ../../linux inline_list
time ./check_export.sh s ../../linux static_list

time ./check_export.sh ie ../../linux init_exit_list
time ./check_export.sh ien ../../linux init_exit_inline_list
time ./check_export.sh iens ../../linux init_exit_inline_static_list

