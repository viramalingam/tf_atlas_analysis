version 1.0

task hello {

  command {
    echo 'hello'
  }
  output {
    File response = stdout()
  }
  runtime {
   docker: 'vivekramalingam/tf-atlas'
  }
}

workflow test {
  call hello
}
