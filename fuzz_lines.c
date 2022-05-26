extern "C" int LLVMFuzzerTestOneInput(const uint8_t *Data, size_t Size) {
  printf("%d\n", Size);
  return 0;
}