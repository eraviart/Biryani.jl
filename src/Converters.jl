# Converters -- A conversion and validation toolbox
# By: Emmanuel Raviart <emmanuel@raviart.com>
#
# Copyright (C) 2015 Etalab
# https://github.com/etalab/Converters.jl
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


module Converters


export call, check, condition, Convertible, empty_to_nothing, fail, input_to_email, input_to_int, pipe, require, string_to_email, strip, struct, test_between, test_greater_or_equal, test, test_isa, to_int, uniform_array, value_error_couple


import Base: strip


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


domain_re = r"""
  (?:[a-z0-9][a-z0-9\-]{0,62}\.)+ # (sub)domain - alpha followed by 62max chars (63 total)
  [a-z]{2,}$                      # TLD
  """ix
username_re = r"[^ \t\n\r@<>()]+$"i


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
  return convertible::Convertible -> begin
    if convertible.error !== nothing || convertible.value === nothing && !handle_nothing
      return convertible
    end
    return Convertible(func(convertible.value), convertible.context)
  end
end


function check(convertible::Convertible)
  """Check a conversion and either return its value or raise an *ErrorException* exception."""
  if convertible.error !== nothing
    error(eval_error(convertible.context, convertible.error))
  end
  return convertible.value
end


function condition(test_converter, ok_converter, error_converter = nothing)
  """When test_converter* succeeds (ie no error), then apply *ok_converter*, otherwise apply *error_converter*.

  .. note:: See also :func:`first_match`.
  """
  return convertible::Convertible -> begin
    converted = test_converter(convertible)
    return converted.error === nothing ?
      ok_converter(convertible) :
      error_converter === nothing ? convertible : error_converter(convertible)
  end
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

eval_error(context::Context, func::Function) = func(context)

eval_error(context::Context, ::Nothing) = nothing

eval_error(context::Context, message::String) = _(context, message)


function fail(; error = nothing)
  """Return a converter that always returns an error."""
  return convertible::Convertible -> begin
    if convertible.error !== nothing
      return convertible
    end
    return Convertible(
      convertible.value,
      convertible.context,
      error === nothing ? N_("An error occured.") : error,
    )
  end
end


input_to_email(convertible::Convertible) = pipe(strip, string_to_email)(convertible)
"""Convert a string to an email address."""


input_to_int(convertible::Convertible) = pipe(strip, to_int)(convertible)
"""Convert a string to an integer."""


function pipe(converters::Function...)
  """Return a compound converter that applies each of its converters till the end or an error occurs."""
  return convertible::Convertible -> begin
    for converter in converters
      convertible = converter(convertible)
      @assert typeof(convertible) <: Convertible
    end
    return convertible
  end
end


require(convertible::Convertible) = convertible.error === nothing && convertible.value === nothing ?
  Convertible(convertible.value, convertible.context, N_("Missing value.")) :
  convertible
"""Return an error when value is ``nothing``."""


function string_to_email(convertible::Convertible)
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
  if !ismatch(username_re, username)
    return Convertible(value, convertible.context, N_("Invalid username."))
  end
  if !ismatch(domain_re, domain) && domain != "localhost"
    return Convertible(value, convertible.context, N_("Invalid domain name."))
  end
  return Convertible(value, convertible.context)
end


strip(convertible::Convertible) = pipe(call(strip), empty_to_nothing)(convertible)
"""Strip spaces from a string and remove it when empty."""


function struct(converters::Dict; default = nothing)
  """Return a converter that maps a dictionary of converters to a dictionary of values."""
  return convertible::Convertible -> begin
    if convertible.error !== nothing || convertible.value === nothing
      return convertible
    end
    if default == "drop"
      converter_by_key = converters
    else
      converter_by_key = copy(converters)
      for key in keys(convertible.value)
        if !haskey(converter_by_key, key)
          converter_by_key[key] = default === nothing ? fail(error = N_("Unexpected item.")) : default
        end
      end
    end
    converted_value_by_key = (String => Any)[]
    error_by_key = (String => Any)[]
    for (key, converter) in converter_by_key
      converted = converter(Convertible(get(convertible.value, key, nothing), convertible.context))
      converted_value_by_key[key] = converted.value
      if converted.error !== nothing
        error_by_key[key] = converted.error
      end
    end
    return Convertible(converted_value_by_key, convertible.context, isempty(error_by_key) ? nothing : error_by_key)
  end
end


function struct(converters::Tuple; default = nothing)
  """Return a converter that maps a tuple of converters to a tuple (or array) of values."""
  return convertible::Convertible -> begin
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
          default === nothing ? fail(error = N_("Unexpected item.")) : default,
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
  return convertible::Convertible -> begin
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


function test_greater_or_equal(min_value; error = nothing)
  """Return a converter that accepts only values greater than or equal to given value.

  .. warning:: Like most converters, a ``nothing`` value is not compared.
  """
  return test(
    value -> min_value <= value,
    error = error === nothing ? context -> _(context, "Value must be greater than or equal to $min_value.") : error,
  )
end


function test_isa(data_type::DataType; error = nothing)
  """Return a converter that accepts only an instance of given type."""
  return test(
    value -> isa(value, data_type),
    error = error === nothing ? context -> _(context, "Value must be an instance of $data_type.") : error,
  )
end


function to_int(convertible::Convertible)
  """Convert any Julia data to an integer.

  .. warning:: Like most converters, a ``nothing`` value is not converted.
  """
  if convertible.error !== nothing || convertible.value === nothing
    return convertible
  end
  return to_int(convertible.value, convertible.context)
end

function to_int(value, context::Context)
  try
    return Convertible(convert(Int, value), context)
  catch
    return Convertible(value, context, N_("Value must be an integer."))
  end
end

function to_int(value::String, context::Context)
  try
    return Convertible(int(value), context)
  catch
    return Convertible(value, context, N_("Value must be an integer."))
  end
end


function uniform_array(converters::Function...; drop_nothing = false, item_type = nothing)
  """Return a converter that applies the same converter to each value of an array."""
  return convertible::Convertible -> begin
    if convertible.error !== nothing || convertible.value === nothing
      return convertible
    end
    errors = (Int => Any)[]
    values = Any[]
    for (index, value) in enumerate(convertible.value)
      converted = pipe(converters...)(Convertible(value, convertible.context))
      if !drop_nothing || converted.value !== nothing
        push!(values, converted.value)
      end
      if converted.error !== nothing
        errors[index] = converted.error
      end
    end
    return Convertible(
      collect(item_type === nothing ? mapreduce(typeof, promote_type, Nothing, values) : item_type, values),
      convertible.context,
      isempty(errors) ? nothing : errors,
    )
  end
end


value_error_couple(convertible::Convertible) = (convertible.value, eval_error(convertible.context, convertible.error))


# TODO: rename input_to_int to parseint. Same thing for input_to_float.


end # module
