version 1.0

task hello {

  command {
    echo $PWD
    cd /
    mkdir my_data
    cd /scratch/
    ls
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
