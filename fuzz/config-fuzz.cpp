#include <string_view>
#include <tao/config.hpp>

extern "C" int LLVMFuzzerTestOneInput( const uint8_t* Data, size_t Size ) {
   auto vi = std::string_view((char*)Data, Size);
   try {
      tao::config::from_string(vi, "");
   }
   catch (const tao::pegtl::parse_error& ex) {
    // Occurs often
   }

   return 0;
}