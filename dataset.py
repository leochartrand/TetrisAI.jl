import json
import os
import argparse
from pathlib import Path
from typing import Tuple, List, Dict
import random
from collections import defaultdict

# ==
DEFAULT_DATASET_SIZE = 50
DEFAULT_HOLD_TOLERENCE = 0.035
DEFAULT_OUTPUT_FILE = 'dataset.json'
DEFAULT_SEED = 0
# == 
DATA_PATH = Path('./data/')
STATES_PATH = DATA_PATH / 'states'
LABELS_PATH = DATA_PATH / 'labels'
SCOREBOARD_PATH = DATA_PATH / 'scoreboard'



def collect_data():

    states_files = [os.path.join(STATES_PATH, file) for file in os.listdir(STATES_PATH) if not file.startswith(".")]
    labels_files = [os.path.join(LABELS_PATH, file) for file in os.listdir(LABELS_PATH) if not file.startswith(".")]

    states_files.sort()
    labels_files.sort()

    states = []
    labels = []

    for sf in states_files:
        with open(sf) as f:
            # Lire les lignes
            lines = f.readlines()
            _states = json.loads(lines[0])
            states.append(_states)

    for sf in labels_files:
        with open(sf) as f:
            # Lire les lignes
            lines = f.readlines()
            _labels = json.loads(lines[0])
            labels.append(_labels)
    
    with open(SCOREBOARD_PATH) as f:
        # Lire les lignes
        lines = f.readlines()

        scores = []

        for line in lines:
            line_mod = line.strip().split(':')
            score = int(line_mod[1])
            scores.append(score)

    return states, labels, scores


def write_scoreboard(scoreboard: List[Tuple[str, int]], filename: str):
    with open(filename, 'w') as f:
        for game_id, score in scoreboard:
            f.write(f"{game_id} : {score}\n")


def sort_games(states: List, labels: List, scores: List, reverse: bool=False):

    indexes = list(range(len(scores)))

    indexes.sort(key=scores.__getitem__, reverse=reverse)

    states = map(states.__getitem__, indexes)
    labels = map(labels.__getitem__, indexes)
    scores = map(scores.__getitem__, indexes)

    return states, labels, scores


def get_label_stats_for_game(game_labels : List[Dict[str, int]]):
    stats = defaultdict(float)
    N = 0.
    for label in game_labels:
        stats[list(label.values())[0]] += 1.
        N += 1.
    for key in stats.keys():
        stats[key] /= N

    return stats


def clean_games(states_lists: List, labels_lists: List, scores: List, hold_tolerence: float):

    if hold_tolerence < 0 or hold_tolerence > 1:
        print("[WARNING] hold_tolerence must be a value between [0, 1]")

    clean_states = []
    clean_labels = []
    clean_scores = []
    for game_states, game_labels, game_score in zip(states_lists, labels_lists, scores):
        hold_freq = get_label_stats_for_game(game_labels)[7]
        if not hold_freq > hold_tolerence:
            clean_states.append(game_states)
            clean_labels.append(game_labels)
            clean_scores.append(game_score)
        else:
            print(f'Too many holds: {hold_freq}')

    print(f'Sanity check: best score = {clean_scores[-1]} == 57600')
    print(f'Sanity check: num games = {len(clean_scores)}')

    return clean_states, clean_labels, clean_scores


def select_games(N, states: List, labels: List, ordered_scores: List):
    return states[-N:], labels[-N:], ordered_scores[-N:]


def assemble(states_list: List, labels_list: List):
    states = [state for game_states in states_list for state in game_states]
    labels = [label for game_states in labels_list for label in game_states]

    print(f'Sanity check: num labels = {len(labels)}')
    
    return states, labels

    
def shuffle(states: List, labels: List):
    tuples = list(zip(states,labels))
    random.shuffle(tuples)
    states, labels = zip(*tuples)
    return states, labels
    

def write_dataset(states: List, labels: List, filename: str):
    json_states = json.dumps(states)
    json_labels = json.dumps(labels)

    states_path = DATA_PATH / ('states-' + filename)
    labels_path = DATA_PATH / ('labels-' + filename)
    
    with open(states_path, 'w') as states_file:
        states_file.write(json_states)

    with open(labels_path, 'w') as labels_file:
        labels_file.write(json_labels)

    return states_path, labels_path


def main(args):
    print("Parameters: ")
    print("Seed: \t\t", args.seed)
    print("hold_tolerence:\t", args.hold_tolerence)
    print("shuffle:\t", not args.no_shuffle)
    print("N:\t\t", args.N)
    print("output:\t\t", args.output)

    random.seed(args.seed)

    # Decider limite
    states, labels, scores = collect_data()
    
    # Sort games in descending score order
    states, labels, scores = sort_games(states, labels, scores, reverse=False)
    
    # Clean up
    states, labels, scores = clean_games(states, labels, scores, args.hold_tolerence)

    # Selection des meilleurs games
    states, labels, scores = select_games(args.N, states, labels, scores)

    # Assembler les donnees
    states, labels = assemble(states, labels)
    
    # Shuffle (avec meme seed!)
    if not args.no_shuffle:
        states, labels = shuffle(states, labels)

    # Write to file
    states_path, labels_path = write_dataset(states, labels, args.output)
    print("Dataset successfully written to ", str(states_path), " and ", str(labels_path))

if '__main__' == __name__:
    parser = argparse.ArgumentParser(
        prog='Tetris Dataset Parser',
        description='Parses and selects appropriate training data for Tetris'
    )
    
    parser.add_argument('--N', help='Size of the dataset', default=DEFAULT_DATASET_SIZE, type=int)
    parser.add_argument('--hold_tolerence', help='Tolerence of the number of hold action [0, 1]', type=float, default=DEFAULT_HOLD_TOLERENCE)
    parser.add_argument('--output', help='Output filename in which to export the filtered dataset', type=str, default=DEFAULT_OUTPUT_FILE)
    parser.add_argument('--no_shuffle', help='Disable the shuffling of the states-labels pairs between games.', action='store_false')
    parser.add_argument('--seed', help='Shuffling seed for the states-labels pairs.', type=int, default=DEFAULT_SEED)

    main(parser.parse_args())