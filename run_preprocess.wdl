version 1.0

task hello {

  command {
    echo 'hello'
  }
  output {
    File response = stdout()
  }
  runtime {
   docker: 'ubuntu:latest'
  }
}

workflow test {
  call hello
}
