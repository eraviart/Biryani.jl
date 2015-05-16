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


module Biryani


export _, call, condition, Convertible, default, embed_error, empty_to_nothing, extract_when_singleton, fail,
  first_match, from_value, guess_bool, input_to_bool, input_to_email, input_to_float, input_to_int, input_to_url_name,
  item_or_sequence, item_to_singleton, log_info, log_warning, N_, noop, pipe, require, string_to_email, strip, struct,
  test, test_between, test_equal, test_greater_or_equal, test_in, test_isa, test_nothing, to_bool, to_float, to_int,
  to_string, to_value, to_value_error, uniform_mapping, uniform_sequence


import Base: strip

import Compat: pipe
import DataStructures: OrderedDict


include("base.jl")


module DatesConverters


  export date_to_iso8601_string, iso8601_input_to_date, iso8601_string_to_date, to_date


  import Dates: Date

  import ..Biryani: call, Context, Convertible, N_, pipe, strip, test


  include("dates.jl")


end  # module DatesConverters


module JsonConverters


  export input_to_json


  import JSON

  import ..Biryani: Convertible, N_


  include("json.jl")


end  # module JsonConverters


module SlugifyConverters


  export input_to_slug


  import Slugify: slugify

  import ..Biryani: Convertible


  include("slug.jl")


end  # module SlugifyConverters


end  # module Biryani
