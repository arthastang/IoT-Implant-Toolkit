import os
import sys
import argparse

def odex2jar(path):

	for root, dirs, files in os.walk(path):
	    for name in files:
	        if name.endswith(".odex"):
	            odexpath = os.path.join(root, name) #.odex
	            dexpath1 = os.path.dirname(odexpath) #.dex
	            dexfile = name.replace(".odex",".dex")
	            dexpath2 = os.path.join(dexpath1, dexfile)
	            jarfile = name.replace(".odex",".jar")
	            jarpath = os.path.join(os.path.dirname(odexpath),jarfile)
	            order = "odex2jar.bat"+" "+ odexpath+" "+ dexpath1 +" "+ dexpath2 + " " + jarpath  
	            os.system(order)
	            #print(order)
	        # if name.endswith(".apk"):
	        # 	apkpath = os.path.join(root, name) #.apk
	        # 	jarpath = apkpath.replace(".apk",".jar")
	        # 	order = "apk2jar.bat"+" "+ apkpath+" "+ jarpath
	        # 	#print(order)
	        # 	os.system(order)
                

if __name__ == "__main__" :
	parser = argparse.ArgumentParser()
	parser.add_argument('-p', '--path', default='D:\\priv-app\\priv-app', type=str, help='-p <filepath>')
	args = parser.parse_args()

	odex2jar(args.path)
