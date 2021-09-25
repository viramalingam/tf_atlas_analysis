version 1.0

task hello {

  command {
    echo $PWD
    ls \
    ls ~
    echo 'adda'	
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
