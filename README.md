## Toy Repo for learning new packages and dev ops

This repo is mainly used for personal learning, particularly on the dev ops side with job scheduling etc.

### Auto-updating using bash scripting -- using bash script to enable auto_updates by writing commands to the command line

currently, run.sh takes in arguments: name, key, and port and prints them out to the terminal every 3 seconds along with a random message

The version tracking will be done through changing the random message function

```bash
pm2 start run.sh --user "ExampleName" --key "ExampleKey" --port 1234
```

### Testing code formatters
black - this python package automatically checks and reformats code that is non-compliant to the PEP-8 standards.
It specifically only checks for line length and indentation

formatting is done via: black <python file> 
can execute check without in-place reformatting using: black --check <python file>

pylint - this is a code reviewing tool that reviews and scores your code.

review is done via: pylint <python file>

### Testing rsync, system loggers, and cron jobs
To improve monitoring, we would like to run a cron job for rsync of log files from remote machines to our host

Key factors include:
- setting up rsync without password
- recording the CPU stats
- system logging to a log file
- error handling for when host machine is not available for the rsync
