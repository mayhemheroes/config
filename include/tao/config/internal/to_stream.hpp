// Copyright (c) 2018-2020 Dr. Colin Hirsch and Daniel Frey
// Please see LICENSE for license or visit https://github.com/taocpp/config/

#ifndef TAO_CONFIG_INTERNAL_TO_STREAM_HPP
#define TAO_CONFIG_INTERNAL_TO_STREAM_HPP

#include <ostream>

#include "format_traits.hpp"

namespace tao::config::internal
{
   template< typename T >
   void to_stream( std::ostream& os, const T& t )
   {
      json::jaxn::events::to_stream consumer( os );
      json::events::produce< format_traits >( consumer, t );
   }

   template< typename T >
   void to_stream( std::ostream& os, const T& t, const std::size_t indent )
   {
      json::jaxn::events::to_pretty_stream consumer( os, indent );
      json::events::produce< format_traits >( consumer, t );
   }

}  // namespace tao::config::internal

#endif
