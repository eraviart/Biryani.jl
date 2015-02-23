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


function input_to_json(convertible::Convertible)
  """Convert a JSON string to Julia data.

  .. warning:: Like most converters, a ``nothing`` value is not converted.
  """
  if convertible.error !== nothing || convertible.value === nothing
    return convertible
  end
  try
    value = JSON.parse(convertible.value)
    return Convertible(value, convertible.context)
  catch exception
    if isa(exception, BoundsError) || isa(exception, ErrorException)
      return Convertible(convertible.value, convertible.context, N_("Invalid JSON"))
    else
      rethrow()
    end
  end
end
