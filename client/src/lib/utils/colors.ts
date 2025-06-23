export const getBaseColor = (capTypeId: number): string => {
  const color_id = capTypeId % 4;
  if (color_id == 0) {
    return "darkred";
  } else if (color_id == 1) {
    return "darkblue";
  } else if (color_id == 2) {
    return "yellow";
  } else if (color_id == 3) {
    return "darkgreen";
  }
  return "darkgrey";
};

export const teams = [0, 1, 2, 3];

export const teamColors: { [key: number]: string } = {
  0: "darkred",
  1: "darkblue",
  2: "yellow",
  3: "darkgreen",
}; 