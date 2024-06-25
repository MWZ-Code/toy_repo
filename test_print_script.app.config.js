module.exports = {
      apps : [{
        name   : 'test_print_script',
        script : 'some_package/main.py',
        interpreter: 'python3',
        min_uptime: '5m',
        max_restarts: '5',
        args: ["'--name'","'test_print_script'","'--'","'--user'","'ExampleName'","'--key'","'ExampleKey'","'--port'","'1234'"]
      }]
    }
