// Fuzz harness for taocpp/config — parse arbitrary bytes as a tao::config document.
// Ported from the archived fork's fuzz/config-fuzz.cpp (same entry point, tao::config::from_string).
// Catches std::exception (not just pegtl::parse_error): config member functions like (include ...)
// and (read ...) legitimately throw filesystem/config errors on fuzzer-generated paths — those are
// expected parse-level rejections, not defects. Memory-safety/UB defects surface via ASan/UBSan.
#include <cstddef>
#include <cstdint>
#include <exception>
#include <string_view>

#include <tao/config.hpp>

extern "C" int LLVMFuzzerTestOneInput( const uint8_t* Data, size_t Size )
{
   const std::string_view vi( reinterpret_cast< const char* >( Data ), Size );
   try {
      (void)tao::config::from_string( vi, "fuzz-input" );
   }
   catch( const std::exception& ) {
      // parse/semantic/filesystem rejection — expected for malformed inputs
   }
   return 0;
}
