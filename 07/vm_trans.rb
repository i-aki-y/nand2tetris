require 'optparse'
require 'pathname'
require './vm_parser'

def trans_vm(vm_file, writer)
  codes = []
  parser = Parser.new({"input_path" => vm_file})
  writer.set_file_name(vm_file)

  while parser.has_more_command?
    parser.advance
    code = ""
    case parser.command_type
    when C_ARITHMETIC
      code = writer.make_arithmetic(parser.arg1)
    when C_PUSH
      code = writer.make_push(parser.command_type, parser.arg1, parser.arg2)
    when C_POP
      code = writer.make_pop(parser.command_type, parser.arg1, parser.arg2)
    when C_LABEL
      code = writer.make_label(parser.arg1)
    when C_GOTO
      code = writer.make_goto(parser.arg1)
    when C_IF
      code = writer.make_if_goto(parser.arg1)
    when C_FUNCTION
      code = writer.make_func(parser.arg1, parser.arg2)
    when C_CALL
      code = writer.make_call_func(parser.arg1, parser.arg2)
    when C_RETURN
      code = writer.make_return()

    end
    if !code.empty?
      codes.push(code)
    end
  end

  return codes.join("\n")
end


def main

  opt = OptionParser.new
  params = Hash.new
  opt.on('-i [path]', 'Input file or directory path') {|v| params[:input_path] = Pathname(v) }
  opt.on('--bootstrap','Insert bootstrap code') {|v| params[:bootstrap] = v }

  opt.parse(ARGV)

  bootstrap = params[:bootstrap]
  input_path = params[:input_path]

  if input_path.directory?
    vm_files = input_path.children.select{ |e| e.fnmatch("*.vm")}
    out_fname = input_path.basename.sub_ext(".asm")
    output_path = input_path / out_fname
  else
    vm_files = [input_path]
    output_path = input_path.sub_ext(".asm")
  end

  if !input_path.exist?
    raise "There isn't such a file #{input_path}"
  end


  writer = CodeWriter.new
  code_init = writer.make_init
  codes = vm_files.collect do |vm_file| trans_vm(vm_file, writer) end

  if bootstrap
    codes = codes.unshift(code_init)
  end

  code = codes.join("\n")

  File.open(output_path.to_s, "w") do |of|
    of.puts code
  end
end

if __FILE__ == $0
    main
end
