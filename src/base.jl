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


abstract Context


type Convertible
  value
  context::Context
  error
end

Convertible(value, context::Context) = Convertible(value, context, nothing)
Convertible(value) = Convertible(value, EmptyContext())


type EmptyContext <: Context
end


_(context::EmptyContext, message::String) = message


N_(message) = message


function call(func::Function; handle_nothing = false)
  """Return a converter that applies a function to value and returns a new value.

  .. note:: Like most converters, by default a ``nothing`` value is not converted (ie function is not
     called). Set ``handle_nothing`` to ``true`` to call function when value is ``nothing``.

  .. note:: When your function doesn't modify value but may generate an error, use a :func:`test` instead.

  .. note:: When your function modifies value and may generate an error, write a full converter instead of a function.

  See :doc:`how-to-create-converter` for more information.
  """
  return function run_call(convertible::Convertible)
    if convertible.error !== nothing || convertible.value === nothing && !handle_nothing
      return convertible
    end
    return Convertible(func(convertible.value), convertible.context)
  end
end


function condition(converters::Function...)
  """When first converter succeeds (ie no error), then apply the second converter, otherwise test the third converter...

  When the number of converters is odd, the last converter is applied when all tests have failed (ie: its is an "else"
  converter).

  .. note:: See also :func:`first_match`.
  """
  return function run_condition(convertible::Convertible)
    last_index = length(converters)
    ok = false
    for (index, converter) in enumerate(converters)
      if index & 1 == 0
        if ok
          return converter(convertible)
        end
      elseif index == last_index
        # Else converter
        return converter(convertible)
      elseif converter(convertible).error === nothing
        # Test converter is OK.
        ok = true
      end
    end
    # Every test has failed and there is no else clause. Return the input convertible.
    return convertible
  end
end


function default(value)
  """Return a converter that replace a ``nothing`` value with given one.

  .. note:: See converter :func:`from_value` to replace a non-``default`` value.
  """
  return function run_default(convertible::Convertible)
    if convertible.error !== nothing || convertible.value !== nothing
      return convertible
    end
    return Convertible(value, convertible.context)
  end
end


function embed_error(value, error)
  """Embed errors inside value.

  .. note:: value is modified. No copy is made.
  """
  if error === nothing
    return nothing
  end
  if isa(value, Union(Dict, OrderedDict))
    if isa(error, Union(Dict, OrderedDict))
      for (child_key, child_error) in error
        child_error = embed_error(get(value, child_key, nothing), child_error)
        if child_error !== nothing
          errors = get!(value, "errors", (typeof(child_key) => Any)[])
          errors[child_key] = child_error
        end
      end
    else
      value["errors"] = error
    end
    return nothing
  end
  if isa(value, Array) && isa(error, Union(Dict, OrderedDict))
    if all(key -> isa(key, Integer) && 1 <= key <= size(value, 1), error)
      for (child_index, child_error) in error
        child_error = embed_error(value[child_index], child_error)
        @assert(child_error === nothing, child_error)
        # if child_error !== nothing
        #   return error
        # end
      end
      return nothing
    end
    if all(key -> isa(key, String) && isdigit(key) && 1 <= int(key) <= size(value, 1), error)
      for (child_key, child_error) in error
        child_error = embed_error(value[int(child_key)], child_error)
        @assert(child_error === nothing, child_error)
        # if child_error !== nothing
        #   return error
        # end
      end
      return nothing
    end
  end
  return error
end


function empty_to_nothing(convertible::Convertible)
  """When value is an empty collection, replace it with ``nothing`` else keep it as is."""
  if convertible.error !== nothing || convertible.value === nothing || !isempty(convertible.value)
    return convertible
  end
  return Convertible(nothing, convertible.context)
end


eval_error(context::Context, error_by_key::Dict) = [
  key => eval_error(context, value)
  for (key, value) in error_by_key
]

function eval_error(context::Context, error_by_key::OrderedDict)
  evaluated_error_by_key = similar(error_by_key)
  for (key, value) in error_by_key
    evaluated_error_by_key[key] = eval_error(context, value)
  end
  return evaluated_error_by_key
end

eval_error(context::Context, func::Function) = func(context)

eval_error(context::Context, ::Nothing) = nothing

eval_error(context::Context, message::String) = _(context, message)


extract_when_singleton(convertible::Convertible) = condition(
  test(value -> length(value) == 1),
  call(value -> value[1]),
)(convertible)
"""Extract first item of sequence when it is a singleton, otherwise keep it unchanged."""


function fail(convertible::Convertible; error = nothing)
  """Always return an error."""
  if convertible.error !== nothing
    return convertible
  end
  return Convertible(
    convertible.value,
    convertible.context,
    error === nothing ? N_("An error occured.") : error,
  )
end

fail(error::String) = convertible::Convertible -> fail(convertible, error = error)

fail(; error::String = nothing) = convertible::Convertible -> fail(convertible, error = error)


function first_match(converters::Function...; error = nothing)
  """Try each converter successively until one succeeds. When every converter fail, return an error.

  .. note:: See also :func:`condition`.
  """
  return function run_first_match(convertible::Convertible)
    if isempty(converters)
      return convertible
    end
    converted = convertible
    for converter in converters
      converted = converter(convertible)
      if converted.error === nothing
        return converted
      end
    end
    return error === nothing ? converted : Convertible(convertible.value, convertible.context, error)
  end
end


function from_value(value)
  """Return a converter that replace any value with given one."""
  return function run_from_value(convertible::Convertible)
    if convertible.error !== nothing
      return convertible
    end
    return Convertible(value, convertible.context)
  end
end


function guess_bool(convertible::Convertible)
  """Convert the content of a string (or a number) to a boolean. Do nothing when input value is already a boolean.

  This converter accepts usual values for ``true`` and ``false``: "0", "f", "false", "n", etc.

  .. warning:: Like most converters, a ``nothing`` value is not converted.

      When you want ``nothing`` to be converted to ``false``, use::

        pipe(guess_bool, default(False))
  """
  if convertible.error !== nothing || convertible.value === nothing
    return convertible
  end
  if !isa(convertible.value, String)
    return to_bool(convertible)
  end
  lower_value = strip(convertible.value) |> lowercase
  if isempty(lower_value)
    return Convertible(nothing, convertible.context)
  end
  if lower_value in ("0", "f", "false", "n", "no", "off")
    value = false
  elseif lower_value in ("1", "on", "t", "true", "y", "yes")
    value = true
  else
    return Convertible(lower_value, convertible.context, N_("Value must be a boolean."))
  end
  return Convertible(value, convertible.context)
end


input_to_bool(convertible::Convertible) = pipe(strip, to_bool)(convertible)
"""Convert a string to a boolean.

.. warning:: Like most converters, a ``nothing`` value is not converted.

  When you want ``nothing`` to be converted to ``false``, use::

    pipe(input_to_bool, default(false))
"""


input_to_email(convertible::Convertible; accept_ip_address = false) = pipe(
  strip,
  string_to_email(accept_ip_address = accept_ip_address),
)(convertible)
"""Convert a string to an email address."""

input_to_email(; accept_ip_address = false) = convertible::Convertible -> input_to_email(convertible,
  accept_ip_address = accept_ip_address)


input_to_float(convertible::Convertible; accept_expression = false) = pipe(
  strip,
  to_float(accept_expression = accept_expression),
)(convertible)
"""Convert a string to a float."""

function input_to_float(; accept_expression = false)
  return convertible::Convertible -> input_to_float(convertible; accept_expression = accept_expression)
end


input_to_int(convertible::Convertible; accept_expression = false) = pipe(
  strip,
  to_int(accept_expression = accept_expression),
)(convertible)
"""Convert a string to an integer number."""

function input_to_int(; accept_expression = false)
  return convertible::Convertible -> input_to_int(convertible; accept_expression = accept_expression)
end


function input_to_url_name(convertible::Convertible; separator = '_', stripmark = false)
  """Normalize a string to allow its use in an URL (or file system) path or a query parameter.

  .. note:: For a converter that keeps only letters, digits and separator, see :func:`input_to_slug`.
  """
  if convertible.error !== nothing || convertible.value === nothing
    return convertible
  end
  value = normalize_string(convertible.value, casefold = true, compat = true, decompose = true, stable = true,
    stripcc = true, stripignore = true, stripmark = stripmark)
  # Replace unsafe characters (for URLs and file-systems).
  value = replace(value, ['\n', '\r', '\\', '/', ';', ':', '"', '#', '*', '?', '&', '<', '>', '|', '.'], ' ')
  value = join(split(value), separator)
  return Convertible(isempty(value) ? nothing : value, convertible.context)
end

function input_to_url_name(; separator = '_', stripmark = false)
  return convertible::Convertible -> input_to_url_name(convertible, separator = separator, stripmark = stripmark)
end


function item_or_sequence(converters::Function...; drop_nothing = false, item_type = nothing, sequence_type = Array)
  """Return a converter that accepts either an item or a sequence of items and applies the given converter to them."""
  return convertible::Convertible -> condition(
    test_isa(sequence_type),
    pipe(
      uniform_sequence(converters..., drop_nothing = drop_nothing, item_type = item_type,
        sequence_type = sequence_type),
      extract_when_singleton,
    ),
    pipe(converters...),
  )(convertible)
end


function item_to_singleton(convertible::Convertible; sequence_type = Array):
  """Convert an item to a singleton, but keep a sequence of items unchanged."""
  if convertible.error !== nothing || convertible.value === nothing || isa(convertible.value, sequence_type)
    return convertible
  end
  # TODO: Use sequence_type to build result value.
  return Convertible([convertible.value], convertible.context)
end


function log_info(convertible::Convertible, messages...)
  """Display value using "info" function."""
  info([string(message) for message in messages]..., "value: ", string(convertible.value), ", type: ",
    string(typeof(convertible.value)), ", error: ", string(convertible.error))
  return convertible
end

log_info(messages...) = convertible::Convertible -> log_info(convertible, messages...)


function log_warning(convertible::Convertible, messages...)
  """Display value using "warn" function."""
  warn([string(message) for message in messages]..., "value: ", string(convertible.value), ", error: ",
    string(convertible.error))
  return convertible
end

log_warning(messages...) = convertible::Convertible -> log_warning(convertible, messages...)


noop(convertible::Convertible) = convertible


function pipe(converters::Function...)
  """Return a compound converter that applies each of its converters till the end or an error occurs."""
  return function run_pipe(convertible::Convertible)
    for converter in converters
      convertible = converter(convertible)
      @assert(typeof(convertible) <: Convertible)
    end
    return convertible
  end
end


require(convertible::Convertible) = convertible.error === nothing && convertible.value === nothing ?
  Convertible(convertible.value, convertible.context, N_("Missing value.")) :
  convertible
"""Return an error when value is ``nothing``."""


function string_to_email(convertible::Convertible; accept_ip_address = false)
  """Convert a clean string to an email address.

  .. note:: For a converter that doesn't require a clean string, see :func:`input_to_email`.
  """
  if convertible.error !== nothing || convertible.value === nothing
    return convertible
  end
  value = lowercase(convertible.value)
  if beginswith(value, "mailto:")
    value = replace(value, "mailto:", "", 1)
  end
  split_value = split(value, '@')
  if length(split_value) != 2
    return Convertible(value, convertible.context, N_("""An email must contain exactly one "@"."""))
  end
  username, domain = split_value
  if !ismatch(r"[^ \t\n\r@<>()]+$"i, username)
    return Convertible(value, convertible.context, N_("Invalid username."))
  end
  if domain != "localhost" &&
      !ismatch(r"""
        ^(?:[a-z0-9][a-z0-9\-]{0,62}\.)+ # (sub)domain - alpha followed by 62max chars (63 total)
        [a-z]{2,}$                      # TLD
      """ix, domain) &&
      (!accept_ip_address || !ismatch(r"^\d+\.\d+\.\d+\.\d+$", domain))
    return Convertible(value, convertible.context, N_("Invalid domain name."))
  end
  return Convertible(value, convertible.context)
end

string_to_email(; accept_ip_address = false) = convertible::Convertible -> string_to_email(convertible,
  accept_ip_address = accept_ip_address)


strip(convertible::Convertible) = pipe(call(strip), empty_to_nothing)(convertible)
"""Strip spaces from a string and remove it when empty."""


function struct(converters::Dict; default = nothing, drop_missing = false, drop_nothing = false)
  """Return a converter that maps a dictionary of converters to a dictionary of values."""
  return function run_struct(convertible::Convertible)
    if convertible.error !== nothing || convertible.value === nothing
      return convertible
    end
    if default == "drop"
      converter_by_key = converters
    else
      converter_by_key = copy(converters)
      for key in keys(convertible.value)
        if !haskey(converter_by_key, key)
          converter_by_key[key] = default === nothing ? fail(N_("Unexpected item.")) : default
        end
      end
    end
    converted_value_by_key = (String => Any)[]
    error_by_key = (String => Any)[]
    for (key, converter) in converter_by_key
      converted = converter(Convertible(get(convertible.value, key, nothing), convertible.context))
      if converted.value !== nothing || (!drop_nothing && (!drop_missing || key in convertible.value))
        converted_value_by_key[key] = converted.value
      end
      if converted.error !== nothing
        error_by_key[key] = converted.error
      end
    end
    return Convertible(converted_value_by_key, convertible.context, isempty(error_by_key) ? nothing : error_by_key)
  end
end


function struct(converters::Tuple; default = nothing)
  """Return a converter that maps a tuple of converters to a tuple (or array) of values."""
  return function run_struct(convertible::Convertible)
    if convertible.error !== nothing || convertible.value === nothing
      return convertible
    end
    values = convertible.value
    if default == "drop"
      values_converter = converters
    else
      values_converter = converters
      while length(values) > length(values_converter)
        values_converter = tuple(
          values_converter...,
          default === nothing ? fail(N_("Unexpected item.")) : default,
        )
      end
    end
    while length(values) < length(values_converter)
      values = tuple(values..., nothing)
    end
    converted_values = cell(length(values_converter))
    error_by_index = (Int => Any)[]
    for (index, (converter, value)) in enumerate(zip(values_converter, values))
      converted = converter(Convertible(value, convertible.context))
      converted_values[index] = converted.value
      if converted.error !== nothing
        error_by_index[index] = converted.error
      end
    end
    return Convertible(
      tuple(converted_values...),
      convertible.context,
      isempty(error_by_index) ? nothing : error_by_index,
    )
  end
end


function test(func; error = nothing, handle_nothing = false)
  """Return a converter that applies a test function to a value and returns an error when test fails.

  ``test`` always returns the initial value, even when test fails.

   See :doc:`how-to-create-converter` for more information.
  """
  return function run_test(convertible::Convertible)
    if convertible.error !== nothing || convertible.value === nothing && !handle_nothing || func(convertible.value)
      return convertible
    end
    return Convertible(
      convertible.value,
      convertible.context,
      error === nothing ? N_("Test failed.") : error,
    )
  end
end


function test_between(min_value, max_value; error = nothing)
  """Return a converter that accepts only values between the two given bounds (included).

  .. warning:: Like most converters, a ``nothing`` value is not compared.
  """
  return test(
    value -> min_value <= value <= max_value,
    error = error === nothing ? context -> _(context, "Value must be between $min_value and $max_value.") : error,
  )
end


function test_equal(comparison_value; error = nothing, handle_nothing = false)
  """Return a converter that accepts only values equals to given value.

  .. warning:: Like most converters, a ``nothing`` value is not compared.
  """
  return test(
    value -> value == comparison_value,
    error = error === nothing ? context -> _(context, "Value must be equal to $comparison_value.") : error,
    handle_nothing = handle_nothing,
  )
end


function test_greater_or_equal(min_value; error = nothing)
  """Return a converter that accepts only values greater than or equal to given value.

  .. warning:: Like most converters, a ``nothing`` value is not compared.
  """
  return test(
    value -> min_value <= value,
    error = error === nothing ? context -> _(context, "Value must be greater than or equal to $min_value.") : error,
  )
end


function test_in(values::Dict; error = nothing, handle_nothing = false)
  """Return a converter that accepts only values belonging to the keys of a given dictionary.

  .. warning:: Like most converters, a ``nothing`` value is not compared.
  """
  values_key = keys(values)
  return test(
    value -> value in values_key,
    error = error === nothing ? context -> _(
      context,
      string(
        "Value must belong to ",
        length(values_key) > 5 ? string(join(collect(values_key)[1:5], ", "), "..") : values_key,
        ".",
      ),
    ) : error,
    handle_nothing = handle_nothing,
  )
end

function test_in(values::Set; error = nothing, handle_nothing = false)
  """Return a converter that accepts only values belonging to a given set.

  .. warning:: Like most converters, a ``nothing`` value is not compared.
  """
  return test(
    value -> value in values,
    error = error === nothing ? context -> _(
      context,
      string(
        "Value must belong to ",
        length(values) > 5 ? string(join(collect(values)[1:5], ", "), "..") : collect(values),
        ".",
      ),
    ) : error,
    handle_nothing = handle_nothing,
  )
end

function test_in(values; error = nothing, handle_nothing = false)
  """Return a converter that accepts only values belonging to a given set (or array or...).

  .. warning:: Like most converters, a ``nothing`` value is not compared.
  """
  return test(
    value -> value in values,
    error = error === nothing ? context -> _(
      context,
      string(
        "Value must belong to ",
        length(values) > 5 ? string(join(values[1:5], ", "), "..") : values,
        ".",
      ),
    ) : error,
    handle_nothing = handle_nothing,
  )
end


function test_isa(data_type::Union(DataType, UnionType); error = nothing, handle_nothing = false)
  """Return a converter that accepts only an instance of given type."""
  return test(
    value -> isa(value, data_type),
    error = error === nothing ? context -> _(context, "Value must be an instance of $data_type.") : error,
    handle_nothing = handle_nothing,
  )
end


function to_bool(convertible::Convertible)
  """Convert a julia data to a boolean.

  .. note:: For a converter that doesn't require a clean string, see :func:`input_to_bool`.

  .. note:: For a converter that accepts special strings like "f", "off", "no", etc, see :func:`guess_bool`.

  .. warning:: Like most converters, a ``nothing`` value is not converted.

    When you want ``nothing`` to be converted to ``false``, use::

      pipe(str_to_bool, default(False))
  """
  if convertible.error !== nothing || convertible.value === nothing
    return convertible
  end
  return to_bool(convertible.value, convertible.context)
end

function to_bool(value, context::Context)
  try
    return Convertible(bool(convert(Int, value)), context)
  catch
    return Convertible(value, context, N_("Value must be a boolean."))
  end
end

function to_bool(value::String, context::Context)
  try
    return Convertible(bool(int(value)), context)
  catch
    return Convertible(value, context, N_("Value must be a boolean."))
  end
end


function to_float(convertible::Convertible; accept_expression = false)
  """Convert a Julia data to a float number.

  .. warning:: Like most converters, a ``nothing`` value is not converted.
  """
  if convertible.error !== nothing || convertible.value === nothing
    return convertible
  end
  value = convertible.value
  if accept_expression && isa(value, String)
    value = strip(value)
    if !ismatch(r"^[ \t\n\r\d.+\-*/()]+$", value)
      return Convertible(value, convertible.context, N_("Value must be a valid floating point expression."))
    end
    try
      value = eval(parse(value))
    catch
      return Convertible(value, convertible.context, N_("Value must be a valid floating point expression."))
    end
  end
  return to_float(value, convertible.context)
end

function to_float(; accept_expression = false)
  return convertible::Convertible -> to_float(convertible; accept_expression = accept_expression)
end

function to_float(value::String, context::Context)
  try
    return Convertible(float(value), context)
  catch
    return Convertible(value, context, N_("Value must be a float number."))
  end
end

function to_float(value, context::Context)
  try
    return Convertible(convert(Float64, value), context)
  catch
    return Convertible(value, context, N_("Value must be a float number."))
  end
end


function to_int(convertible::Convertible; accept_expression = false)
  """Convert a Julia data to an integer number.

  .. warning:: Like most converters, a ``nothing`` value is not converted.
  """
  if convertible.error !== nothing || convertible.value === nothing
    return convertible
  end
  value = convertible.value
  if accept_expression && isa(value, String)
    value = strip(value)
    if !ismatch(r"^[ \t\n\r\d.+\-*/()]+$", value)
      return Convertible(value, convertible.context, N_("Value must be a valid integer expression."))
    end
    try
      value = eval(parse(value))
    catch
      return Convertible(value, convertible.context, N_("Value must be a valid integer expression."))
    end
  end
  return to_int(value, convertible.context)
end

function to_int(; accept_expression = false)
  return convertible::Convertible -> to_int(convertible; accept_expression = accept_expression)
end

function to_int(value::String, context::Context)
  try
    return Convertible(int(value), context)
  catch
    return Convertible(value, context, N_("Value must be an integer number."))
  end
end

function to_int(value, context::Context)
  try
    return Convertible(convert(Int, value), context)
  catch
    return Convertible(value, context, N_("Value must be an integer number."))
  end
end


function to_string(convertible::Convertible)
  """Convert a Julia data to a string.

  .. warning:: Like most converters, a ``nothing`` value is not converted.
  """
  if convertible.error !== nothing || convertible.value === nothing
    return convertible
  end
  return Convertible(string(convertible.value), convertible.context)
end


function to_value(convertible::Convertible)
  """Check a conversion and either return its value or raise an *ErrorException* exception."""
  if convertible.error !== nothing
    error(eval_error(convertible.context, convertible.error), "\nValue: ", convertible.value)
  end
  return convertible.value
end


to_value_error(convertible::Convertible) = (convertible.value, eval_error(convertible.context, convertible.error))


function uniform_mapping(key_converter::Function, value_converters::Function...; drop_nothing = false,
    drop_nothing_keys = false, key_type = nothing, value_type = nothing)
  """Return a converter that applies a unique converter to each key and another one to each value of a mapping."""
  # TODO: Handle constructor.
  return function run_uniform_mapping(convertible::Convertible)
    if convertible.error !== nothing || convertible.value === nothing
      return convertible
    end
    error_by_key = (Any => Any)[]
    value_by_key = OrderedDict(Any, Any)
    for (key, value) in convertible.value
      key_converted = key_converter(Convertible(key, convertible.context))
      if key_converted.error !== nothing
        error_by_key[key] = key_converted.error
      end
      if drop_nothing_keys && key_converted.value === nothing
        continue
      end
      value_converted = pipe(value_converters...)(Convertible(value, convertible.context))
      if !drop_nothing || value_converted.value !== nothing
        value_by_key[key_converted.value] = value_converted.value
      end
      if value_converted.error !== nothing
        error_by_key[key_converted.value] = value_converted.error
      end
    end

    typed_value_by_key = OrderedDict(
      key_type === nothing ?
        (isempty(value_by_key) ? Any : mapreduce(typeof, promote_type, Nothing, keys(value_by_key))) :
        key_type,
      value_type === nothing ?
        (isempty(value_by_key) ? Any : mapreduce(typeof, promote_type, Nothing, values(value_by_key))) :
        value_type,
    )
    for (key, value) in value_by_key
      typed_value_by_key[key] = value
    end

    if isempty(error_by_key)
      return Convertible(typed_value_by_key, convertible.context)
    else
      typed_error_by_key = OrderedDict(
        key_type === nothing ? mapreduce(typeof, promote_type, Nothing, keys(error_by_key)) : key_type,
        value_type === nothing ? mapreduce(typeof, promote_type, Nothing, values(error_by_key)) : value_type,
      )
      for (key, error) in error_by_key
        typed_error_by_key[key] = error
      end
      return Convertible(typed_value_by_key, convertible.context, typed_error_by_key)
    end
  end
end


function uniform_sequence(converters::Function...; drop_nothing = false, item_type = nothing, sequence_type = Array)
  """Return a converter that applies the same converter to each value of an array."""
  # TODO: Handle constructor or sequence_type.
  return function run_uniform_sequence(convertible::Convertible)
    if convertible.error !== nothing || convertible.value === nothing
      return convertible
    end
    error_by_index = (Int => Any)[]
    values = Any[]
    for (index, value) in enumerate(convertible.value)
      converted = pipe(converters...)(Convertible(value, convertible.context))
      if !drop_nothing || converted.value !== nothing
        push!(values, converted.value)
      end
      if converted.error !== nothing
        error_by_index[index] = converted.error
      end
    end
    return Convertible(
      collect(item_type === nothing ?
        (isempty(values) ? Any : mapreduce(typeof, promote_type, Nothing, values)) :
        item_type, values),
      convertible.context,
      isempty(error_by_index) ? nothing : error_by_index,
    )
  end
end
