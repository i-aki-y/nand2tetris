require 'optparse'
require 'pathname'
require './jack_tokenizer'
require './compilation_engine'

def main
  opt = OptionParser.new
  params = Hash.new
  opt.on('-i [path]', 'Input file or directory path') {|v| params[:input_path] = Pathname(v) }
  opt.on('--tokenize', 'Output tokenized file') {|v| params[:tokenize] = true }
  opt.on('--vm', 'Output tokenized file') {|v| params[:vm] = true }

  opt.parse(ARGV)


  input_path = params[:input_path]
  is_tokenize = params[:tokenize]
  is_vm = params[:vm]

  if is_tokenize
    output_path = input_path.sub_ext("T_.xml")
  elsif is_vm
    output_path = input_path.sub_ext(".vm")
  else
    output_path = input_path.sub_ext("_.xml")
  end

  if !input_path.exist?
    raise "There isn't such a file #{input_path}"
  end

  input = get_input(input_path)

  tokenizer = JackTokenizer.new()
  tokenizer.set_input(input)

  if is_tokenize
    xml = tokenizer.dump_xml
    File.open(output_path, "w") { |f| f.puts(xml) }
  else
    engine = CompilationEngine.new(tokenizer)
    engine.compile
    vm_cmds = engine.dump_vm
    File.open(output_path, "w") { |f| f.puts(vm_cmds) }
  end


end

def get_input(input_path)
  File.open(input_path, "r") do |f|
    lines = f.readlines
    return lines.join("\n")
  end

end

main
