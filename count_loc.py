import argparse
import json
import os
import re
import subprocess
import sys

EXTENSIONS_FILE='file_extensions.txt'
MAP_FILE='file_extensions_map.txt'

def print_usage():
	print("""usage: count_loc.py [-h] [-p [PATH]] [-o] [-f] [-e | -m]""")

class readable_dir(argparse.Action):
	def __call__(self, parser, namespace, values, option_string=None):
		prospective_dir=values
		if not os.path.isdir(prospective_dir):
			raise argparse.ArgumentTypeError("readable_dir:{0} is not a valid path".format(prospective_dir))
		if os.access(prospective_dir, os.R_OK):
			setattr(namespace,self.dest,prospective_dir)
		else:
			raise argparse.ArgumentTypeError("readable_dir:{0} is not a readable dir".format(prospective_dir))

def command(c):
	process = subprocess.Popen(c, shell=True, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
	stdin, err = process.communicate()
	return stdin.decode("utf-8")

def get_git_repos(path, filter_by):
	repos = []
	if filter_by == 'filter_by_map':
		with open(MAP_FILE, 'r') as f:
			for repo_map in [l.strip().split(':') for l in f.readlines()]:
				repo_path, extensions = repo_map[0], repo_map[1].split(',')
				repos.append((path + '/' + repo_path, extensions))
	else:
		output = command("find " + path + " -type d -maxdepth 1 -exec test -e '{}/.git' ';' -print -prune")
		repos = output.split('\n')[:-1]
	return repos

def lines_of_code(repo, filter_by, file_level, omit_blank_lines):
	current_dir = command('pwd')

	is_file_name = re.compile(r"""(^\+\+\+.*$)""")
	if not omit_blank_lines:
		is_loc = re.compile(r"""(^\+[^\+]+\s*.*\S+.*$|^\+$)""")
	else:
		is_loc = re.compile(r"""(^\+[^\+]+\s*.*\S+.*$)""")
	
	if filter_by == 'filter_by_extensions':
		repo_name = repo.replace(' ', '\\ ')
		with open(EXTENSIONS_FILE, 'r') as f:
			extensions = ['*.' + e.strip() for e in f.readlines()]
		diff = command(' '.join(['cd', repo_name, ';', "git diff `git hash-object -t tree /dev/null`"] + extensions + [';', 'cd', current_dir]))

	elif filter_by == 'filter_by_map':
		repo_name = repo[0].replace(' ', '\\ ')
		extensions = ['*.' + e for e in repo[1]]
		diff = command(' '.join(['cd', repo_name, ';', "git diff `git hash-object -t tree /dev/null`"] + extensions + [';', 'cd', current_dir]))

	else:
		repo_name = repo.replace(' ', '\\ ')
		diff = command(' '.join(['cd', repo_name, ';', "git diff `git hash-object -t tree /dev/null`", ';', 'cd', current_dir]))
		
	total = 0
	files = {}
	current_file = ''
	for l in diff.split('\n'):
		if is_file_name.match(l):
			current_file = l[6:]
			files[current_file] = 0
		elif is_loc.match(l):
			files[current_file] += 1
			total += 1
		
	if file_level:
		return files, total
	else:
		return total

def arguments():
	
	try:
		parser = argparse.ArgumentParser(description='Count Lines of Code in Git Repos')

		parser.add_argument('-p', '--path', action=readable_dir, nargs='?', default='.',
							help='Path to folder with Git Repos to be scanned')
		parser.add_argument('-o', '--omit-blank-lines', action='store_true',
							help='Omit all blank lines of code')
		parser.add_argument('-f', '--file-level-counts', action='store_true',
							help='Get a line count by each file in repo')
		parser.add_argument('-e', '--filter-by-extensions', action='store_true',
							help='Filter files by certain file extensions in file_extensions.txt')
		parser.add_argument('-m', '--filter-by-map', action='store_true',
							help='Filter files by extensions for each git repo in file_extensions_map.txt')

		args = parser.parse_args()
		
		filter_by=''
		if sum([args.filter_by_extensions, args.filter_by_map]) > 1:
			print("You can only filter by one method at a time.")
			print_usage()
			sys.exit(1)

		elif args.filter_by_extensions:
			filter_by='filter_by_extensions'
		elif args.filter_by_map:
			filter_by='filter_by_map'
		else:
			filter_by='None'

		return (args.path, filter_by, args.file_level_counts, args.omit_blank_lines)

	except argparse.ArgumentTypeError:
		print_usage()
		sys.exit(1)

def write_output(line_counts, file_level, filter_by):
	with open('lines_per_repo.csv', 'w') as rf:
		rf.write('Repo Path' + ',' + 'Total Line Count' + '\n')
		if file_level:
			with open('lines_per_file.csv', 'w') as lf:
				lf.write('Repo Path' + ',' + 'File' + ',' + 'File Line Count' + '\n')
				for repo, lines in line_counts:
					file_totals = lines[0]
					total = lines[1]
					if filter_by == 'filter_by_map':
						repo_name = repo[0]
					else:
						repo_name = repo
					rf.write(repo_name + ',' + str(total) + '\n')
					for file in file_totals:
						lf.write(repo_name + ',' + file + ',' + str(file_totals[file]) + '\n')
		else:
			for repo, total in line_counts:
				rf.write(repo + ',' + str(total) + '\n')
def main():
	path, filter_by, file_level, omit_blank_lines = arguments()
	repos = get_git_repos(path, filter_by)
	line_counts = [(repo, lines_of_code(repo, filter_by, file_level, omit_blank_lines)) for repo in repos]
	write_output(line_counts, file_level, filter_by)

if __name__ == '__main__':
	main()