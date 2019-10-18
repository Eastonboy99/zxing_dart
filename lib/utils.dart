
void arraycopy(List src, int srcPos, List dest, int destPos, int length) {
  dest.setRange(destPos, length + destPos, src, srcPos);
}

int bitCount(int bits){

  var bitString = bits.toRadixString(2);
  var count = 0;
  for (var i = 0; i < bitString.length; i++) {
    if (bitString[i] == '1'){
      count++;
    }
  }
  
  return count;
}