# Biryani -- A conversion and validation toolbox
# By: Emmanuel Raviart <emmanuel@raviart.com>
#
# Copyright (C) 2015 Emmanuel Raviart
# https://github.com/eraviart/Biryani.jl
#
# This file is part of Biryani.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


import Dates: Date

importall Biryani.DatesConverters


# iso8601_input_to_date
@test Convertible("2012-03-04") |> iso8601_input_to_date |> to_value == Date(2012, 3, 4)
@test Convertible("2012-03") |> iso8601_input_to_date |> to_value == Date(2012, 3, 1)
@test Convertible("2012") |> iso8601_input_to_date |> to_value == Date(2012, 1, 1)
@test Convertible("   2012-03-04\n  ") |> iso8601_input_to_date |> to_value == Date(2012, 3, 4)
@test Convertible("   2012-03\n  ") |> iso8601_input_to_date |> to_value == Date(2012, 3, 1)
@test Convertible("   2012\n  ") |> iso8601_input_to_date |> to_value == Date(2012, 1, 1)
@test Convertible("2012-03-04 05:06:07") |> iso8601_input_to_date |> to_value_error == ("2012-03-04 05:06:07",
  "Invalid ISO-8601 format for date.")
@test Convertible("2012-03-04T05:06:07") |> iso8601_input_to_date |> to_value_error == ("2012-03-04T05:06:07",
  "Invalid ISO-8601 format for date.")
@test Convertible("today") |> iso8601_input_to_date |> to_value_error == ("today", "Invalid ISO-8601 format for date.")
@test Convertible("   \n  ") |> iso8601_input_to_date |> to_value === nothing


# iso8601_string_to_date
@test Convertible("2012-03-04") |> iso8601_string_to_date |> to_value == Date(2012, 3, 4)
@test Convertible("2012-03") |> iso8601_string_to_date |> to_value == Date(2012, 3, 1)
@test Convertible("2012") |> iso8601_string_to_date |> to_value == Date(2012, 1, 1)
@test Convertible("2012-03-04 05:06:07") |> iso8601_string_to_date |> to_value_error == ("2012-03-04 05:06:07",
  "Invalid ISO-8601 format for date.")
@test Convertible("2012-03-04T05:06:07") |> iso8601_string_to_date |> to_value_error == ("2012-03-04T05:06:07",
  "Invalid ISO-8601 format for date.")
@test Convertible("today") |> iso8601_string_to_date |> to_value_error == ("today", "Invalid ISO-8601 format for date.")
@test Convertible("") |> iso8601_string_to_date |> to_value_error == ("", "Invalid ISO-8601 format for date.")
@test Convertible(nothing) |> iso8601_string_to_date |> to_value === nothing


# to_date
@test Convertible("2015-01-01") |> to_date |> to_value == Date(2015, 1, 1)
