## unit test
ruby test_assembler.rb

## add
../../tools/Assembler.sh add/Add.asm
mv add/Add.hack add/Add.cmp
echo "Add.cmp is made"

ruby asm.rb add/Add.asm
echo "Add.hack is made"

echo "check diff"
diff add/Add.cmp add/Add.hack

## max
../../tools/Assembler.sh max/Max.asm
mv max/Max.hack max/Max.cmp
echo "Max.cmp is made"

ruby asm.rb max/Max.asm
echo "Max.hack is made"

echo "check diff"
diff max/Max.cmp max/Max.hack

## maxL
../../tools/Assembler.sh max/MaxL.asm
mv max/MaxL.hack max/MaxL.cmp
echo "MaxL.cmp is made"

ruby asm.rb max/MaxL.asm
echo "MaxL.hack is made"

echo "check diff"
diff max/MaxL.cmp max/MaxL.hack

## rect
../../tools/Assembler.sh rect/Rect.asm
mv rect/Rect.hack rect/Rect.cmp
echo "Rect.cmp is made"

ruby asm.rb rect/Rect.asm
echo "Rect.hack is made"

echo "check diff"
diff rect/Rect.cmp rect/Rect.hack


## rectL
../../tools/Assembler.sh rect/RectL.asm
mv rect/RectL.hack rect/RectL.cmp
echo "RectL.cmp is made"

ruby asm.rb rect/RectL.asm
echo "RectL.hack is made"

echo "check diff"
diff rect/RectL.cmp rect/RectL.hack

## pong
../../tools/Assembler.sh pong/Pong.asm
mv pong/Pong.hack pong/Pong.cmp
echo "Pong.cmp is made"

ruby asm.rb pong/Pong.asm
echo "Pong.hack is made"

echo "check diff"
diff pong/Pong.cmp pong/Pong.hack


## pong
../../tools/Assembler.sh pong/PongL.asm
mv pong/PongL.hack pong/PongL.cmp
echo "PongL.cmp is made"

ruby asm.rb pong/PongL.asm
echo "PongL.hack is made"

echo "check diff"
diff pong/PongL.cmp pong/PongL.hack
