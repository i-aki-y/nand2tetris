require 'optparse'
require 'pathname'
require './jack_tokenizer'
require './compilation_engine'

def main
  opt = OptionParser.new
  params = Hash.new
  opt.on('-i [path]', 'Input file or directory path') {|v| params[:input_path] = Pathname(v) }
  opt.on('-tokenize', 'Output tokenized file') {|v| params[:tokenize] = true }

  opt.parse(ARGV)

  input_path = params[:input_path]
  is_tokenize = params[:tokenize]

  if is_tokenize
    output_path = input_path.sub_ext("T_.xml")
  else
    output_path = input_path.sub_ext("_.xml")
  end

  if !input_path.exist?
    raise "There isn't such a file #{input_path}"
  end

  File.open(input_path, "r") do |f|
    lines = f.readlines
  end

  tokenizer = JackTokenizer.new()
  tokenizer.set_input(lines.join("\n"))

  if is_tokenize
    xml = tokenizer.dump_xml
    File.open(output_path, "w") { |f| f.puts(xml) }
  else
    engine = CompilationEngine.new(tokenizer)
    xml = engine.dump_xml
    File.open(output_path, "w") { |f| f.puts(xml) }
  end


end
