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


# Test converters.


# call
@test Convertible("42") |> call(int) |> to_value == 42
@test Convertible([3, 2, 1]) |> call(sort) |> to_value == [1, 2, 3]
@test Convertible(42) |> call(value -> value + 1) |> to_value == 43
@test Convertible(nothing) |> call(value -> value + 1) |> to_value === nothing
@test_throws MethodError Convertible("hello world") |> call(value -> value + 1) |> to_value
@test_throws MethodError Convertible(nothing) |> call(value -> value + 1, handle_nothing = true) |> to_value

# condition
detect_unknown_values = condition(
  test_in(['?', 'x']),
  from_value(false),
  from_value(true),
)
@test Convertible("Hello world!") |> detect_unknown_values |> to_value === true
@test Convertible('x') |> detect_unknown_values |> to_value === false

# default
@test Convertible(nothing) |> default(42) |> to_value == 42
@test Convertible("Hello world!") |> default(42) |> to_value == "Hello world!"
@test Convertible("    \n  ") |> input_to_int |> default(42) |> to_value == 42
@test Convertible(nothing) |> input_to_int |> default(42) |> to_value == 42

# empty_to_nothing
@test Convertible("") |> empty_to_nothing |> to_value === nothing
@test Convertible("Hello world!") |> empty_to_nothing |> to_value == "Hello world!"
@test Convertible(" ") |> empty_to_nothing |> to_value == " "
@test Convertible(" ") |> strip |> empty_to_nothing |> to_value === nothing
@test Convertible([]) |> empty_to_nothing |> to_value === nothing
@test Convertible([42, 43]) |> empty_to_nothing |> to_value == [42, 43]
@test Convertible({}) |> empty_to_nothing |> to_value === nothing
@test Convertible(["answer" => 42]) |> empty_to_nothing |> to_value == ["answer" => 42]
@test Convertible(nothing) |> empty_to_nothing |> to_value === nothing

# extract_when_singleton
@test Convertible([42]) |> extract_when_singleton |> to_value == 42
@test Convertible([42, 43]) |> extract_when_singleton |> to_value == [42, 43]
@test Convertible([]) |> extract_when_singleton |> to_value == []
@test Convertible(nothing) |> extract_when_singleton |> to_value === nothing

# fail
@test Convertible(42) |> fail |> to_value_error == (42, "An error occured.")
@test Convertible(42) |> fail("Wrong answer.") |> to_value_error == (42, "Wrong answer.")
@test Convertible(nothing) |> fail |> to_value_error == (nothing, "An error occured.")

# first_match
@test Convertible(42) |> first_match(to_int, test_equal("NaN")) |> to_value == 42
@test Convertible("NaN") |> first_match(to_int, test_equal("NaN")) |> to_value == "NaN"
@test Convertible("Hello world!") |> first_match(to_int, test_equal("NaN")) |> to_value_error == ("Hello world!",
  "Value must be equal to NaN.")
@test Convertible("Hello world!") |> first_match(to_int, test_equal("NaN"),
  error = "Value must be a integer or NaN.") |> to_value_error == ("Hello world!", "Value must be a integer or NaN.")
@test Convertible("Hello world!") |> first_match(to_int, test_equal("NaN"), from_value(0)) |> to_value == 0
@test Convertible("Hello world!") |> first_match() |> to_value == "Hello world!"
@test Convertible("Hello world!") |> first_match(error = "An error occured.") |> to_value == "Hello world!"
@test Convertible(nothing) |> first_match(to_int, test_equal("NaN")) |> to_value === nothing

# from_value
@test Convertible("Answer to the Ultimate Question of Life, the Universe, and Everything") |> from_value(42) |>
  to_value == 42
@test Convertible(nothing) |> from_value(42) |> to_value == 42
@test Convertible("Hello world!") |> fail |> from_value(42) |> to_value_error == ("Hello world!", "An error occured.")

# guess_bool
@test Convertible("0") |> guess_bool |> to_value === false
@test Convertible("f") |> guess_bool |> to_value === false
@test Convertible("FALSE") |> guess_bool |> to_value === false
@test Convertible("false") |> guess_bool |> to_value === false
@test Convertible("n") |> guess_bool |> to_value === false
@test Convertible("no") |> guess_bool |> to_value === false
@test Convertible("off") |> guess_bool |> to_value === false
@test Convertible("   0\n  ") |> guess_bool |> to_value === false
@test Convertible("   f\n  ") |> guess_bool |> to_value === false
@test Convertible(false) |> guess_bool |> to_value === false
@test Convertible("1") |> guess_bool |> to_value === true
@test Convertible("on") |> guess_bool |> to_value === true
@test Convertible("t") |> guess_bool |> to_value === true
@test Convertible("TRUE") |> guess_bool |> to_value === true
@test Convertible("true") |> guess_bool |> to_value === true
@test Convertible("y") |> guess_bool |> to_value === true
@test Convertible("yes") |> guess_bool |> to_value === true
@test Convertible("   1\n  ") |> guess_bool |> to_value === true
@test Convertible("   tRUE\n  ") |> guess_bool |> to_value === true
@test Convertible(true) |> guess_bool |> to_value === true
@test Convertible(1) |> guess_bool |> to_value === true
@test Convertible(2) |> guess_bool |> to_value === true
@test Convertible(-1) |> guess_bool |> to_value === true
@test Convertible("") |> guess_bool |> to_value === nothing
@test Convertible("   \n  ") |> guess_bool |> to_value === nothing
@test Convertible(nothing) |> guess_bool |> to_value === nothing
@test Convertible("vrai") |> guess_bool |> to_value_error == ("vrai", "Value must be a boolean.")

# input_to_bool
@test Convertible("0") |> input_to_bool |> to_value === false
@test Convertible("   0\n  ") |> input_to_bool |> to_value === false
@test Convertible("1") |> input_to_bool |> to_value === true
@test Convertible("   1\n  ") |> input_to_bool |> to_value === true
@test Convertible("42") |> input_to_bool |> to_value === true
@test Convertible("   \n  ") |> input_to_bool |> to_value === nothing
@test Convertible(nothing) |> input_to_bool |> to_value === nothing
@test Convertible("vrai") |> input_to_bool |> to_value_error == ("vrai", "Value must be a boolean.")
@test Convertible("on") |> input_to_bool |> to_value_error == ("on", "Value must be a boolean.")

# input_to_email
@test Convertible("john@doe.name") |> input_to_email |> to_value == "john@doe.name"
@test Convertible("mailto:john@doe.name") |> input_to_email |> to_value == "john@doe.name"
@test Convertible("root@localhost") |> input_to_email |> to_value == "root@localhost"
@test Convertible("root@127.0.0.1") |> input_to_email |> to_value_error == ("root@127.0.0.1",
  "Invalid domain name.")
@test Convertible("root@127.0.0.1") |> input_to_email(accept_ip_address = true) |> to_value == "root@127.0.0.1"
@test Convertible("root") |> input_to_email |> to_value_error == ("root",
  """An email must contain exactly one "@".""")
@test Convertible("    john@doe.name\n  ") |> input_to_email |> to_value == "john@doe.name"
@test Convertible(nothing) |> input_to_email |> to_value === nothing
@test Convertible("    \n  ") |> input_to_email |> to_value === nothing

# input_to_float
@test Convertible("42") |> input_to_float |> to_value == 42.0
@test Convertible("   42.75\n  ") |> input_to_float |> to_value == 42.75
@test Convertible("Hello world!") |> input_to_float |> to_value_error == ("Hello world!",
  "Value must be a float number.")
@test Convertible("(42 / 42 + 1) * 42 - 42") |> input_to_float |> to_value_error == ("(42 / 42 + 1) * 42 - 42",
  "Value must be a float number.")
@test Convertible("(42 / 42 + 1) * 42 - 42") |> input_to_float(accept_expression = true) |> to_value == 42.0
@test Convertible("pi / 2") |> input_to_float(accept_expression = true) |> to_value_error == ("pi / 2",
  "Value must be a valid floating point expression.")
@test Convertible("1 / 3") |> input_to_float(accept_expression = true) |> to_value == 0.3333333333333333
@test Convertible(nothing) |> input_to_float |> to_value === nothing

# input_to_int
@test Convertible("42") |> input_to_int |> to_value == 42
@test Convertible("   42\n") |> input_to_int |> to_value == 42
@test Convertible("42.75") |> input_to_int |> to_value_error == ("42.75", "Value must be an integer number.")
@test Convertible("(42 / 42 + 1) * 42 - 42") |> input_to_int |> to_value_error == ("(42 / 42 + 1) * 42 - 42",
  "Value must be an integer number.")
@test Convertible("(42 / 42 + 1) * 42 - 42") |> input_to_int(accept_expression = true) |> to_value == 42
@test Convertible("pi / 2") |> input_to_int(accept_expression = true) |> to_value_error == ("pi / 2",
  "Value must be a valid integer expression.")
@test Convertible("1 / 3") |> input_to_int(accept_expression = true) |> to_value_error == (0.3333333333333333,
  "Value must be an integer number.")
@test Convertible(nothing) |> input_to_int |> to_value === nothing

# input_to_url_name
@test Convertible("   Hello \n world!\n  ") |> input_to_url_name |> to_value == "hello_world!"
@test Convertible("   Hello \n world!\n  ") |> input_to_url_name(separator = ' ') |> to_value == "hello world!"
@test Convertible(nothing) |> input_to_url_name |> to_value === nothing
@test Convertible("    \n  ") |> input_to_url_name |> to_value === nothing

# item_or_sequence
@test Convertible("42") |> item_or_sequence(input_to_int) |> to_value == 42
@test Convertible(["42"]) |> item_or_sequence(input_to_int) |> to_value == 42
@test Convertible(["42", "43"]) |> item_or_sequence(input_to_int) |> to_value == [42, 43]
@test Convertible(["42", "43", "Hello world!"]) |> item_or_sequence(input_to_int) |> to_value_error == (
  [42, 43, "Hello world!"], [3 => "Value must be an integer number."])
@test Convertible(nothing) |> item_or_sequence(input_to_int) |> to_value === nothing
@test Convertible([nothing]) |> item_or_sequence(input_to_int, drop_nothing = true) |> to_value == []
@test Convertible([nothing, nothing]) |> item_or_sequence(input_to_int) |> to_value == [nothing, nothing]
@test Convertible([nothing, nothing]) |> item_or_sequence(input_to_int, drop_nothing = true) |> to_value == []
@test Convertible(["42", "    \n  ", "43"]) |> item_or_sequence(input_to_int) |> to_value == [42, nothing, 43]
@test Convertible(["42", "    \n  ", "43"]) |> item_or_sequence(input_to_int, drop_nothing = true) |> to_value == [42,
  43]

# item_to_singleton
@test Convertible("Hello world!") |> item_to_singleton |> to_value == ["Hello world!"]
@test Convertible(["Hello world!"]) |> item_to_singleton |> to_value == ["Hello world!"]
@test Convertible([42, "Hello world!"]) |> item_to_singleton |> to_value == [42, "Hello world!"]
@test Convertible([]) |> item_to_singleton |> to_value == []
@test Convertible(nothing) |> item_to_singleton |> to_value == nothing

# pipe
@test_throws MethodError Convertible(42) |> input_to_bool
@test_throws MethodError Convertible(42) |> pipe(input_to_bool)
@test Convertible(42) |> pipe(test_isa(String), input_to_bool) |> to_value_error == (42,
  "Value must be an instance of String.")
@test Convertible(42) |> pipe(to_string, input_to_bool) |> to_value === true
@test Convertible(42) |> pipe() |> to_value == 42

# require
@test Convertible(42) |> require |> to_value == 42
@test Convertible("") |> require |> to_value == ""
@test Convertible(nothing) |> require |> to_value_error == (nothing, "Missing value.")
@test Convertible("   \n  ") |> strip |> require |> to_value_error == (nothing, "Missing value.")

# strip
@test Convertible("   Hello world!\n   ") |> strip |> to_value == "Hello world!"
@test Convertible("   \n   ") |> strip |> to_value === nothing
@test Convertible(nothing) |> strip |> to_value === nothing

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
]) |> dict_strict_converter |> to_value == [
  "name" => "John Doe",
  "age" => 72,
  "email" => "john@doe.name",
]
@test Convertible([
  "name" => "John Doe",
  "email" => "john@doe.name",
]) |> dict_strict_converter |> to_value == [
  "name" => "John Doe",
  "age" => nothing,
  "email" => "john@doe.name",
]
@test Convertible([
  "name" => "John Doe",
  "age" => nothing,
  "email" => "john@doe.name",
]) |> dict_strict_converter |> to_value == [
  "name" => "John Doe",
  "age" => nothing,
  "email" => "john@doe.name",
]
@test Convertible([
  "name" => "John Doe",
  "age" => "72",
  "email" => "john@doe.name",
  "phone" => "   +33 9 12 34 56 78   ",
]) |> dict_strict_converter |> to_value_error == (
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
]) |> dict_non_strict_converter |> to_value == [
  "name" => "John Doe",
  "age" => 72,
  "email" => "john@doe.name",
]
@test Convertible([
  "name" => "John Doe",
  "email" => "john@doe.name",
]) |> dict_non_strict_converter |> to_value == [
  "name" => "John Doe",
  "age" => nothing,
  "email" => "john@doe.name",
]
@test Convertible([
  "name" => "John Doe",
  "age" => "72",
  "email" => "john@doe.name",
  "phone" => "   +33 9 12 34 56 78   ",
]) |> dict_non_strict_converter |> to_value == [
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
]) |> tuple_strict_converter |> to_value == (
  "John Doe",
  72,
  "john@doe.name",
)
@test Convertible([
  "John Doe",
  nothing,
  "john@doe.name",
]) |> tuple_strict_converter |> to_value == (
  "John Doe",
  nothing,
  "john@doe.name",
)
@test Convertible([
  "John Doe",
  "72",
  "john@doe.name",
  "   +33 9 12 34 56 78   ",
]) |> tuple_strict_converter |> to_value_error == (
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
]) |> tuple_non_strict_converter |> to_value == (
  "John Doe",
  72,
  "john@doe.name",
)
@test Convertible([
  "John Doe",
  nothing,
  "john@doe.name",
]) |> tuple_non_strict_converter |> to_value == (
  "John Doe",
  nothing,
  "john@doe.name",
)
@test Convertible([
  "John Doe",
  "72",
  "john@doe.name",
  "   +33 9 12 34 56 78   ",
]) |> tuple_non_strict_converter |> to_value == (
  "John Doe",
  72,
  "john@doe.name",
  "+33 9 12 34 56 78",
)

# test
@test Convertible("hello") |> test(value -> isa(value, String)) |> to_value == "hello"
@test Convertible(1) |> test(value -> isa(value, String)) |> to_value_error == (1, "Test failed.")
@test Convertible(1) |> test(value -> isa(value, String), error = "Value is not a string.") |> to_value_error == (1,
  "Value is not a string.")

# test_between
@test Convertible(5) |> test_between(0, 9) |> to_value == 5
@test Convertible(0) |> test_between(0, 9) |> to_value == 0
@test Convertible(10) |> test_between(0, 9) |> to_value_error == (10, "Value must be between 0 and 9.")
@test Convertible(10) |> test_between(0, 9, error = "Number must be a digit.") |> to_value_error == (10,
  "Number must be a digit.")
@test Convertible(nothing) |> test_between(0, 9) |> to_value === nothing

# test_equal
@test Convertible(42) |> test_equal(42) |> to_value == 42
@test Convertible(["a" => 1, "b" => 2]) |> test_equal(["a" => 1, "b" => 2]) |> to_value == ["a" => 1, "b" => 2]
@test Convertible(41) |> test_equal(42) |> to_value_error == (41, "Value must be equal to 42.")
@test Convertible(41) |> test_equal(42, error = "Value is not the answer.") |> to_value_error == (41,
  "Value is not the answer.")
@test Convertible(42) |> test_equal(nothing) |> to_value_error == (42, "Value must be equal to nothing.")
@test Convertible(nothing) |> test_equal(42) |> to_value === nothing
@test Convertible(nothing) |> test_equal(nothing) |> to_value === nothing

# test_greater_or_equal
@test Convertible(5) |> test_greater_or_equal(0) |> to_value == 5
@test Convertible(5) |> test_greater_or_equal(9) |> to_value_error == (5,
  "Value must be greater than or equal to 9.")
@test Convertible(5) |> test_greater_or_equal(9, error = "Value must be a positive two-digits number.") |>
  to_value_error == (5, "Value must be a positive two-digits number.")
@test Convertible(nothing) |> test_greater_or_equal(0) |> to_value === nothing

# test_in
@test Convertible('a') |> test_in("abcd") |> to_value == 'a'
@test Convertible('a') |> test_in(['a', 'b', 'c', 'd']) |> to_value == 'a'
@test Convertible('z') |> test_in(['a', 'b', 'c', 'd']) |> to_value_error == ('z',
  "Value must belong to Char[a,b,c,d].")
@test Convertible('z') |> test_in(Set('a', 'b', 'c', 'd')) |> to_value_error == ('z',
  "Value must belong to Char[d,b,c,a].")
@test Convertible('z') |> test_in(['a', 'b', 'c', 'd'], error = """Value must be a letter less than "e".""") |>
  to_value_error == ('z', """Value must be a letter less than "e".""")
@test Convertible('z') |> test_in([]) |> to_value_error == ('z', "Value must belong to None[].")
@test_throws MethodError Convertible('z') |> test_in(nothing)

# test_isa
@test Convertible("This is a string.") |> test_isa(String) |> to_value == "This is a string."
@test Convertible(42) |> test_isa(String) |> to_value_error == (42, "Value must be an instance of String.")
@test Convertible(42) |> test_isa(String, error = "Value is not a string.") |> to_value_error == (42,
  "Value is not a string.")
@test Convertible(nothing) |> test_isa(String) |> to_value === nothing

# to_bool
@test Convertible("0") |> to_bool |> to_value === false
@test Convertible("1") |> to_bool |> to_value === true
@test Convertible(42) |> to_bool |> to_value === true
@test Convertible("42") |> to_bool |> to_value === true
@test Convertible(nothing) |> to_bool |> to_value === nothing
@test Convertible("vrai") |> to_bool |> to_value_error == ("vrai", "Value must be a boolean.")
@test Convertible("on") |> to_bool |> to_value_error == ("on", "Value must be a boolean.")

# to_float
@test Convertible(42) |> to_float |> to_value == 42.0
@test Convertible("42") |> to_float |> to_value == 42.0
@test Convertible(42.75) |> to_float |> to_value == 42.75
@test Convertible("42.75") |> to_float |> to_value == 42.75
@test Convertible("   42.75  ") |> to_float |> to_value == 42.75
@test Convertible("   42.75\n  ") |> to_float |> to_value == 42.75
@test Convertible("(42 / 42 + 1) * 42 - 42") |> to_float |> to_value_error == ("(42 / 42 + 1) * 42 - 42",
  "Value must be a float number.")
@test Convertible("(42 / 42 + 1) * 42 - 42") |> to_float(accept_expression = true) |> to_value == 42.0
@test Convertible("pi / 2") |> to_float(accept_expression = true) |> to_value_error == ("pi / 2",
  "Value must be a valid floating point expression.")
@test Convertible("1 / 3") |> to_float(accept_expression = true) |> to_value == 0.3333333333333333
@test Convertible(nothing) |> to_float |> to_value === nothing

# to_int
@test Convertible(42) |> to_int |> to_value == 42
@test Convertible("42") |> to_int |> to_value == 42
@test Convertible("42.75") |> to_int |> to_value_error == ("42.75", "Value must be an integer number.")
@test Convertible("42,75") |> to_int |> to_value_error == ("42,75", "Value must be an integer number.")
@test Convertible("(42 / 42 + 1) * 42 - 42") |> to_int |> to_value_error == ("(42 / 42 + 1) * 42 - 42",
  "Value must be an integer number.")
@test Convertible("(42 / 42 + 1) * 42 - 42") |> to_int(accept_expression = true) |> to_value == 42
@test Convertible("pi / 2") |> to_int(accept_expression = true) |> to_value_error == ("pi / 2",
  "Value must be a valid integer expression.")
@test Convertible("1 / 3") |> to_int(accept_expression = true) |> to_value_error == (0.3333333333333333,
  "Value must be an integer number.")
@test Convertible(nothing) |> to_int |> to_value === nothing

# to_string
@test Convertible(42) |> to_string |> to_value == "42"
@test Convertible("42") |> to_string |> to_value == "42"
@test Convertible(nothing) |> to_string |> to_value === nothing

# uniform_mapping
@test Convertible(["a" => "1", "b" => "2"]) |> uniform_mapping(strip, input_to_int) |> to_value == ["a" => 1, "b" => 2]
@test Convertible(["   answer\n  " => "42"]) |> uniform_mapping(strip, input_to_int) |> to_value == ["answer" => 42]
@test Convertible(["a" => "1", "b" => "2", "c" => 3]) |> uniform_mapping(strip, test_isa(String), input_to_int) |>
  to_value_error == (["a" => 1, "b" => 2, "c" => 3], ["c" => "Value must be an instance of String."])
@test Convertible(["a" => "1", "b" => "2", "c" => 3]) |>
  uniform_mapping(strip, condition(test_isa(String), input_to_int)) |>
  to_value == ["a" => 1, "b" => 2, "c" => 3]
@test Convertible({}) |> uniform_mapping(strip, input_to_int) |> to_value == (Nothing => Nothing)[]
@test Convertible([nothing => "42"]) |> uniform_mapping(strip, input_to_int) |> to_value == [nothing => 42]
@test Convertible(["   \n  " => "42"]) |> uniform_mapping(strip, input_to_int) |> to_value == [nothing => 42]
@test Convertible([nothing => "42"]) |> uniform_mapping(strip, input_to_int, drop_nothing_keys = true) |>
  to_value == (Nothing => Nothing)[]
    # >>> uniform_mapping(cleanup_line, input_to_int)(None)
    # (None, None)
@test Convertible(nothing) |> uniform_mapping(strip, input_to_int) |> to_value === nothing

# uniform_sequence
@test Convertible(["42"]) |> uniform_sequence(input_to_int) |> to_value == [42]
@test Convertible(["42", "43"]) |> uniform_sequence(input_to_int) |> to_value == [42, 43]
@test Convertible(["42", "43", "Hello world!"]) |> uniform_sequence(input_to_int) |> to_value_error == (
  [42, 43, "Hello world!"], [3 => "Value must be an integer number."])
@test Convertible([nothing, nothing]) |> uniform_sequence(input_to_int) |> to_value == [nothing, nothing]
@test Convertible([nothing, nothing]) |> uniform_sequence(input_to_int, drop_nothing = true) |> to_value == []
@test Convertible(["42", "    \n  ", "43"]) |> uniform_sequence(input_to_int) |> to_value == [42, nothing, 43]
@test Convertible(["42", "    \n  ", "43"]) |> uniform_sequence(input_to_int, drop_nothing = true) |> to_value == [42,
  43]


# Test tools.


# .value
@test (Convertible("42") |> input_to_int).value == 42
@test (Convertible("Hello world!") |> input_to_int).value == "Hello world!"

# to_value
@test Convertible("42") |> input_to_int |> to_value == 42
@test_throws ErrorException Convertible("Hello world!") |> input_to_int |> to_value
# @test Convertible(42) |> to_string |> test_isa(String) |> input_to_bool |> to_value === true

# to_value_error
@test Convertible("42") |> input_to_int |> to_value_error == (42, nothing)
@test Convertible("Hello world!") |> input_to_int |> to_value_error == ("Hello world!", "Value must be an integer number.")
# @test Convertible(42) |> to_string |> test_isa(String) |> input_to_bool |> to_value_error === (true, nothing)
