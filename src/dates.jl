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


const year_or_month_or_day_re = r"(18|19|20)\d{2}(-(0[1-9]|1[0-2])(-([0-2]\d|3[0-1]))?)?$"


iso8601_input_to_date(convertible::Convertible) = pipe(strip, iso8601_string_to_date)(convertible)
"""Convert a string in ISO 8601 format to a date."""


iso8601_string_to_date(convertible::Convertible) = pipe(
  test(value -> ismatch(year_or_month_or_day_re, value), error = N_("Invalid ISO-8601 format for date.")),
  call(value -> Date(join(vcat(split(value, '-'), ["01", "01"])[1:3], '-'))),
)(convertible)
"""Convert a clean string in ISO 8601 format to a date.

.. note:: For a converter that doesn't require a clean string, see :func:`iso8601_input_to_date`.
"""


function to_date(convertible::Convertible)
  """Convert a Julia data to a date.

  .. warning:: Like most converters, a ``nothing`` value is not converted.
  """
  if convertible.error !== nothing || convertible.value === nothing
    return convertible
  end
  return to_date(convertible.value, convertible.context)
  # return Convertible(Date(convertible.value), convertible.context)
end

to_date(value::(Int...), context::Context) = Convertible(Date(value...), context)

function to_date(value::String, context::Context)
  if !('-' in value)
    # Work around bug in Julia 0.3: Date("2013") throws:
    # ERROR: ArgumentError("Delimiter mismatch. Couldn't find first delimiter, \"-\", in date string")
    value = string(value, "-1")
  end
  return Convertible(Date(value), context)
end

to_date(value, context::Context) = Convertible(Date(value), context)
