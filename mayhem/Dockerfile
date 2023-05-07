FROM debian:bookworm as builder
RUN apt update && apt install -y clang build-essential

COPY . /config
RUN cp -r /config/external/json/include/tao /config/include && cp -r /config/external/json/external/PEGTL/include/tao /config/include
WORKDIR /config/fuzz

RUN make

FROM debian:bookworm
COPY --from=builder /config/fuzz /