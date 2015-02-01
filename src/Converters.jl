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


export _, call, condition, Convertible, default, empty_to_nothing, extract_when_singleton, fail, from_value, guess_bool, input_to_bool, input_to_email, input_to_float, input_to_int, item_or_sequence, item_to_singleton, log_info, log_warning, N_, noop, pipe, require, string_to_email, strip, struct, test, test_between, test_greater_or_equal, test_in, test_isa, to_bool, to_float, to_int, to_string, to_value, to_value_error, uniform_mapping, uniform_sequence


import Base: strip

import DataStructures: OrderedDict


include("base.jl")


module DatesConverters


  export to_date


  import Dates: Date

  import ..Converters: Context, Convertible


  include("dates.jl")


end  # module DatesConverters


end  # module Converters
