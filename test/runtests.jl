# Converters -- A conversion and validation toolbox
# By: Emmanuel Raviart <emmanuel@raviart.com>
#
# Copyright (C) 2015 Emmanuel Raviart
# https://github.com/eraviart/Converters.jl
#
# This file is part of Converters.
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


using Base.Test

using Converters


# Test converters.


# call
@test Convertible("42") |> call(int) |> check == 42
@test Convertible([3, 2, 1]) |> call(sort) |> check == [1, 2, 3]
@test Convertible(42) |> call(value -> value + 1) |> check == 43
@test Convertible(nothing) |> call(value -> value + 1) |> check === nothing
@test_throws MethodError Convertible("hello world") |> call(value -> value + 1) |> check
@test_throws MethodError Convertible(nothing) |> call(value -> value + 1, handle_nothing = true) |> check

# condition
# detect_unknown_values = condition(
#   test_in(['?', 'x']),
#   set_value(False),
#   set_value(True),
# )
# @test detect_unknown_values("Hello world!") === true
# @test detect_unknown_values("?") === false

# empty_to_nothing
@test Convertible("") |> empty_to_nothing |> check === nothing
@test Convertible("Hello world!") |> empty_to_nothing |> check == "Hello world!"
@test Convertible(" ") |> empty_to_nothing |> check == " "
@test Convertible(" ") |> strip |> empty_to_nothing |> check === nothing
@test Convertible([]) |> empty_to_nothing |> check === nothing
@test Convertible([42, 43]) |> empty_to_nothing |> check == [42, 43]
@test Convertible({}) |> empty_to_nothing |> check === nothing
@test Convertible(["answer" => 42]) |> empty_to_nothing |> check == ["answer" => 42]
@test Convertible(nothing) |> empty_to_nothing |> check === nothing

# extract_when_singleton
@test Convertible([42]) |> extract_when_singleton |> check == 42
@test Convertible([42, 43]) |> extract_when_singleton |> check == [42, 43]
@test Convertible([]) |> extract_when_singleton |> check == []
@test Convertible(nothing) |> extract_when_singleton |> check === nothing

# fail
@test Convertible(42) |> fail() |> value_error_couple == (42, "An error occured.")
@test Convertible(42) |> fail(error = "Wrong answer.") |> value_error_couple == (42, "Wrong answer.")
@test Convertible(nothing) |> fail() |> value_error_couple == (nothing, "An error occured.")

# input_to_email
@test Convertible("john@doe.name") |> input_to_email |> check == "john@doe.name"
@test Convertible("mailto:john@doe.name") |> input_to_email |> check == "john@doe.name"
@test Convertible("root@localhost") |> input_to_email |> check == "root@localhost"
@test Convertible("root@127.0.0.1") |> input_to_email |> value_error_couple == ("root@127.0.0.1",
  "Invalid domain name.")
@test Convertible("root") |> input_to_email |> value_error_couple == ("root",
  """An email must contain exactly one "@".""")
@test Convertible("    john@doe.name\n  ") |> input_to_email |> check == "john@doe.name"
@test Convertible(nothing) |> input_to_email |> check === nothing
@test Convertible("    \n  ") |> input_to_email |> check === nothing

# input_to_int
@test Convertible("42") |> input_to_int |> check == 42
@test Convertible("   42\n") |> input_to_int |> check == 42
@test Convertible("42.75") |> input_to_int |> value_error_couple == ("42.75", "Value must be an integer.")
@test Convertible("42,75") |> input_to_int |> value_error_couple == ("42,75", "Value must be an integer.")
@test Convertible(nothing) |> input_to_int |> check === nothing

# item_or_sequence
@test Convertible("42") |> item_or_sequence(input_to_int) |> check == 42
@test Convertible(["42"]) |> item_or_sequence(input_to_int) |> check == 42
@test Convertible(["42", "43"]) |> item_or_sequence(input_to_int) |> check == [42, 43]
@test Convertible(["42", "43", "Hello world!"]) |> item_or_sequence(input_to_int) |> value_error_couple == (
  [42, 43, "Hello world!"], [3 => "Value must be an integer."])
@test Convertible(nothing) |> item_or_sequence(input_to_int) |> check === nothing
@test Convertible([nothing]) |> item_or_sequence(input_to_int, drop_nothing = true) |> check == []
@test Convertible([nothing, nothing]) |> item_or_sequence(input_to_int) |> check == [nothing, nothing]
@test Convertible([nothing, nothing]) |> item_or_sequence(input_to_int, drop_nothing = true) |> check == []
@test Convertible(["42", "    \n  ", "43"]) |> item_or_sequence(input_to_int) |> check == [42, nothing, 43]
@test Convertible(["42", "    \n  ", "43"]) |> item_or_sequence(input_to_int, drop_nothing = true) |> check == [42, 43]

# pipe
@test Convertible(42) |> pipe() |> check == 42
# >>> input_to_bool(42)
# Traceback (most recent call last):
# AttributeError:
# >>> pipe(input_to_bool)(42)
# Traceback (most recent call last):
# AttributeError:
# >>> pipe(test_isinstance(unicode), input_to_bool)(42)
# (42, u"Value is not an instance of <type 'unicode'>")
# >>> pipe(anything_to_str, test_isinstance(unicode), input_to_bool)(42)
# (True, None)
# >>> pipe()(42)
# (42, None)

# require
@test Convertible(42) |> require |> check == 42
@test Convertible("") |> require |> check == ""
@test Convertible(nothing) |> require |> value_error_couple == (nothing, "Missing value.")
@test Convertible("   \n  ") |> strip |> require |> value_error_couple == (nothing, "Missing value.")

# strip
@test Convertible("   Hello world!\n   ") |> strip |> check == "Hello world!"
@test Convertible("   \n   ") |> strip |> check === nothing
@test Convertible(nothing) |> strip |> check === nothing

# struct
dict_strict_converter = struct(
  [
    "name" => pipe(strip, require),
    "age" => input_to_int,
    "email" => input_to_email,
  ],
)
@test Convertible([
  "name" => "John Doe",
  "age" => "72",
  "email" => "john@doe.name",
]) |> dict_strict_converter |> check == [
  "name" => "John Doe",
  "age" => 72,
  "email" => "john@doe.name",
]
@test Convertible([
  "name" => "John Doe",
  "email" => "john@doe.name",
]) |> dict_strict_converter |> check == [
  "name" => "John Doe",
  "age" => nothing,
  "email" => "john@doe.name",
]
@test Convertible([
  "name" => "John Doe",
  "age" => nothing,
  "email" => "john@doe.name",
]) |> dict_strict_converter |> check == [
  "name" => "John Doe",
  "age" => nothing,
  "email" => "john@doe.name",
]
@test Convertible([
  "name" => "John Doe",
  "age" => "72",
  "email" => "john@doe.name",
  "phone" => "   +33 9 12 34 56 78   ",
]) |> dict_strict_converter |> value_error_couple == (
  [
    "name" => "John Doe",
    "age" => 72,
    "email" => "john@doe.name",
    "phone" => "   +33 9 12 34 56 78   ",
  ],
  [
    "phone" => "Unexpected item.",
  ],
)
dict_non_strict_converter = struct(
  [
    "name" => pipe(strip, require),
    "age" => input_to_int,
    "email" => input_to_email,
  ],
  default = strip,
)
@test Convertible([
  "name" => "John Doe",
  "age" => "72",
  "email" => "john@doe.name",
]) |> dict_non_strict_converter |> check == [
  "name" => "John Doe",
  "age" => 72,
  "email" => "john@doe.name",
]
@test Convertible([
  "name" => "John Doe",
  "email" => "john@doe.name",
]) |> dict_non_strict_converter |> check == [
  "name" => "John Doe",
  "age" => nothing,
  "email" => "john@doe.name",
]
@test Convertible([
  "name" => "John Doe",
  "age" => "72",
  "email" => "john@doe.name",
  "phone" => "   +33 9 12 34 56 78   ",
]) |> dict_non_strict_converter |> check == [
  "name" => "John Doe",
  "age" => 72,
  "email" => "john@doe.name",
  "phone" => "+33 9 12 34 56 78",
]
tuple_strict_converter = struct(
  (
    pipe(strip, require),
    input_to_int,
    input_to_email,
  ),
)
@test Convertible([
  "John Doe",
  "72",
  "john@doe.name",
]) |> tuple_strict_converter |> check == (
  "John Doe",
  72,
  "john@doe.name",
)
@test Convertible([
  "John Doe",
  nothing,
  "john@doe.name",
]) |> tuple_strict_converter |> check == (
  "John Doe",
  nothing,
  "john@doe.name",
)
@test Convertible([
  "John Doe",
  "72",
  "john@doe.name",
  "   +33 9 12 34 56 78   ",
]) |> tuple_strict_converter |> value_error_couple == (
  (
    "John Doe",
    72,
    "john@doe.name",
    "   +33 9 12 34 56 78   ",
  ),
  [
    4 => "Unexpected item.",
  ],
)
tuple_non_strict_converter = struct(
  (
    pipe(strip, require),
    input_to_int,
    input_to_email,
  ),
  default = strip,
)
@test Convertible([
  "John Doe",
  "72",
  "john@doe.name",
]) |> tuple_non_strict_converter |> check == (
  "John Doe",
  72,
  "john@doe.name",
)
@test Convertible([
  "John Doe",
  nothing,
  "john@doe.name",
]) |> tuple_non_strict_converter |> check == (
  "John Doe",
  nothing,
  "john@doe.name",
)
@test Convertible([
  "John Doe",
  "72",
  "john@doe.name",
  "   +33 9 12 34 56 78   ",
]) |> tuple_non_strict_converter |> check == (
  "John Doe",
  72,
  "john@doe.name",
  "+33 9 12 34 56 78",
)

# test
@test Convertible("hello") |> test(value -> isa(value, String)) |> check == "hello"
@test Convertible(1) |> test(value -> isa(value, String)) |> value_error_couple == (1, "Test failed.")
@test Convertible(1) |> test(value -> isa(value, String), error = "Value is not a string.") |> value_error_couple == (1,
  "Value is not a string.")

# test_between
@test Convertible(5) |> test_between(0, 9) |> check == 5
@test Convertible(0) |> test_between(0, 9) |> check == 0
@test Convertible(10) |> test_between(0, 9) |> value_error_couple == (10, "Value must be between 0 and 9.")
@test Convertible(10) |> test_between(0, 9, error = "Number must be a digit.") |> value_error_couple == (10,
  "Number must be a digit.")
@test Convertible(nothing) |> test_between(0, 9) |> check === nothing

# test_greater_or_equal
@test Convertible(5) |> test_greater_or_equal(0) |> check == 5
@test Convertible(5) |> test_greater_or_equal(9) |> value_error_couple == (5,
  "Value must be greater than or equal to 9.")
@test Convertible(5) |> test_greater_or_equal(9, error = "Value must be a positive two-digits number.") |>
  value_error_couple == (5, "Value must be a positive two-digits number.")
@test Convertible(nothing) |> test_greater_or_equal(0) |> check === nothing

# test_isa
@test Convertible("This is a string.") |> test_isa(String) |> check == "This is a string."
@test Convertible(42) |> test_isa(String) |> value_error_couple == (42, "Value must be an instance of String.")
@test Convertible(42) |> test_isa(String, error = "Value is not a string.") |> value_error_couple == (42,
  "Value is not a string.")
@test Convertible(nothing) |> test_isa(String) |> check === nothing

# to_int
@test Convertible(42) |> to_int |> check == 42
@test Convertible("42") |> to_int |> check == 42
@test Convertible("42.75") |> to_int |> value_error_couple == ("42.75", "Value must be an integer.")
@test Convertible("42,75") |> to_int |> value_error_couple == ("42,75", "Value must be an integer.")
@test Convertible(nothing) |> to_int |> check === nothing

# uniform_sequence
@test Convertible(["42"]) |> uniform_sequence(input_to_int) |> check == [42]
@test Convertible(["42", "43"]) |> uniform_sequence(input_to_int) |> check == [42, 43]
@test Convertible(["42", "43", "Hello world!"]) |> uniform_sequence(input_to_int) |> value_error_couple == (
  [42, 43, "Hello world!"], [3 => "Value must be an integer."])
@test Convertible([nothing, nothing]) |> uniform_sequence(input_to_int) |> check == [nothing, nothing]
@test Convertible([nothing, nothing]) |> uniform_sequence(input_to_int, drop_nothing = true) |> check == []
@test Convertible(["42", "    \n  ", "43"]) |> uniform_sequence(input_to_int) |> check == [42, nothing, 43]
@test Convertible(["42", "    \n  ", "43"]) |> uniform_sequence(input_to_int, drop_nothing = true) |> check == [42, 43]


# Test tools.


# .value
@test (Convertible("42") |> input_to_int).value == 42
@test (Convertible("Hello world!") |> input_to_int).value == "Hello world!"

# check
@test Convertible("42") |> input_to_int |> check == 42
@test_throws ErrorException Convertible("Hello world!") |> input_to_int |> check
# @test Convertible(42) |> to_string |> test_isa(String) |> input_to_bool |> check === true

# value_error_couple
@test Convertible("42") |> input_to_int |> value_error_couple == (42, nothing)
@test Convertible("Hello world!") |> input_to_int |> value_error_couple == ("Hello world!", "Value must be an integer.")
# @test Convertible(42) |> to_string |> test_isa(String) |> input_to_bool |> value_error_couple === (true, nothing)
