from some_package.some_utils import print_message
import time

'''
dummy script that just prints a message to terminal every 3 seconds
'''

def main():
    while True:
        print_message()
        time.sleep(3)

if __name__=="__main__":
