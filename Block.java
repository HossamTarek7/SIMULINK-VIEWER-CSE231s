/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package Project;

import java.util.ArrayList;
import javafx.scene.canvas.Canvas;
import javafx.scene.canvas.GraphicsContext;
import javafx.scene.paint.Color;
import javafx.scene.Scene;
import javafx.scene.canvas.Canvas;
import javafx.scene.canvas.GraphicsContext;
import javafx.scene.control.Button;
import javafx.scene.layout.Pane;
import javafx.scene.layout.StackPane;
import javafx.scene.paint.Color;
import javafx.stage.Stage;

/**
 *
 * @author Hossa
 */
public class Block implements Comparable<Block> {

    private String name;
        private String type;
    private int sid;
    private static int number_of_blocks;

    private int[] location = new int[4];

//
    public Block(String name,String typee, int sid, int[] pos_array) {
        this.type=typee;
        this.name = name;
        this.sid = sid;
        this.location = pos_array;
    }

    public static void setNumber_of_blocks(int number_of_blocks) {
        Block.number_of_blocks = number_of_blocks;
    }

    public Block() {
    }

    public String getName() {
        return name;
    }

    public void print() {
                System.out.println("the block type is --->" + this.type);
        System.out.println("the block name is --->" + this.name);
        System.out.println("the sid is --->" + this.sid);
        System.out.println("the vaules are" + this.location[0] + " , " + this.location[1] + " , " + this.location[2] + " , " + this.location[3]);
    }

    public int getX() {
        return (this.location[2]) * 2 - 1000;
    }

    public int getY() {
        return (int) ((this.location[3]) * 1.75 - 200);
    }

    public int startPointx() {
        return (this.location[2]) * 2 - 1000;
    }

    public int endPointx() {
        return (this.location[2]) * 2 - 930;
    }

    public int startPointy() {
        return (int) ((this.location[3]) * 1.75 - 165);
    }

    public int endPointy() {
        return (int) ((this.location[3]) * 1.75 - 165);
    }

    public int getHeight() {
        return 70;
    }

    public int getWidth() {
        return 70;
    }

    public static void drawLines(GraphicsContext gcc, ArrayList<Block> blockss) {

        for (int m = 0; m < blockss.size() - 2; m++) {
            Block block1 = blockss.get(m);
            Block block2 = blockss.get(m + 1);
            int x1 = block1.getX() + 70;
            int y1 = block1.getY() + (block1.getHeight() / 2);
            int x2 = block2.getX();
            int y2 = y1;
            gcc.strokeLine(x1, y1, x2, y2);
        }

    }

    public static void drawBranchLines(GraphicsContext gcc, ArrayList<Block> blockss) {
        int x1, x2, y1, y2;
        x1 = blockss.get(1).startPointx() + 170;
        x2 = x1;
        y1 = blockss.get(1).startPointy();
        y2 = y1 + 19;
        gcc.strokeLine(x1, y1, x2, y2);
        y1 = y2;
        x2 = blockss.get(2).startPointx();
        gcc.strokeLine(x1, y1, x2, y2);
        x1 = blockss.get(3).startPointx() - 28;
        x2 = x1;
        y1 = blockss.get(2).startPointy();
        y2 = blockss.get(4).startPointy();
        gcc.strokeLine(x1, y1, x2, y2);
        y1 = y2;
        x1 = x2;
        x2 = blockss.get(4).endPointx();
        gcc.strokeLine(x1, y1, x2, y2);
        x1 = blockss.get(4).startPointx();
        x2 = x1 - 28;
        gcc.strokeLine(x1, y1, x2, y2);
        y2 = blockss.get(1).startPointy() + 39;
        x1 = x2;
        gcc.strokeLine(x1, y1, x2, y2);
        y1 = y2;
        x1 = x2;
        x2 = blockss.get(2).startPointx();
        gcc.strokeLine(x1, y1, x2, y2);
        gcc.setFill(Color.DARKBLUE);
        gcc.fillOval(blockss.get(1).startPointx() + 167, blockss.get(1).startPointy()-3,7, 7);
          gcc.fillOval(blockss.get(3).startPointx() - 31,blockss.get(2).startPointy()-3,7, 7);
    }

    public void draw(GraphicsContext gcc) {

        gcc.setFill(Color.WHITE);
        gcc.setStroke(Color.BLUE);
        gcc.fillRect((this.location[2]) * 2 - 1000, (this.location[3]) * 1.75 - 200, 70, 70);  //50---->150

        gcc.strokeRect((this.location[2]) * 2 - 1000, (this.location[3]) * 1.75 - 200, 70, 70);
        gcc.strokeText(this.name, (this.location[2]) * 2 - 1000 + 17, (this.location[3]) * 1.75 - 115);

    }

    @Override
    public int compareTo(Block other) {
        // Compare blocks by their x-coordinate
        int x1 = this.location[3];
        int x2 = other.location[3];

        if (x1 < x2) {
            return -1;
        } else if (x1 > x2) {
            return 1;
        } else {
            return 0;
        }
    }
}
