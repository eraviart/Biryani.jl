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


function input_to_slug(convertible::Convertible; separator::Char = '-', transform::Function = lowercase)
  """Simplify a string to a slug (ie a string containing only 0-9, A-Z, a-z & separators)."""
  if convertible.error !== nothing || convertible.value === nothing
    return convertible
  end
  slug = slugify(convertible.value, separator = separator, transform = transform)
  return Convertible(isempty(slug)? nothing : slug , convertible.context)
end

input_to_slug(; separator::Char = '-', transform::Function = lowercase) = convertible::Convertible -> input_to_slug(
  convertible, separator = separator, transform = transform)
