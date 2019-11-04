
import 'dart:core';

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


// String Functions

StringBuffer setCharAt(StringBuffer buffer, int index, String char){
  var newBuffer = new StringBuffer();

    for (var i = 0; i < buffer.length; i++) {
    if (i != index){
      newBuffer.write(buffer.toString()[i]);
    }else{
      newBuffer.write(char);
    }
  }

}

StringBuffer deleteCharAt(StringBuffer buffer, int index){
  var newBuffer = new StringBuffer();

  for (var i = 0; i < buffer.length; i++) {
    if (i != index){
      newBuffer.write(buffer.toString()[i]);
    }
  }

  return newBuffer;
}
