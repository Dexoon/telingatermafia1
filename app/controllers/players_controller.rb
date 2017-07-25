class PlayersController < ApplicationController
  before_action :set_player, only: %i[show edit update destroy]
  before_action :find_player, only: %i[set_score score player]

  def player
    render json: @player, status: 200
  end

  def score
    msg = { id: @player.id, score: @player.score }
    render json: msg, status: 200
  end

  def set_score
    @player.update(score: params[:score])
    msg = { id: @player.id, score: @player.score }
    render json: msg, status: 200
  end

  # GET /players
  # GET /players.json
  def index
    @players = Player.all
  end

  # GET /players/1
  # GET /players/1.json
  def show; end

  # GET /players/new
  def new
    @player = Player.new
  end

  # GET /players/1/edit
  def edit; end

  # POST /players
  # POST /players.json
  def create
    @player = Player.new(player_params)
    respond_to do |format|
      if @player.save
        format.html { redirect_to @player, notice: 'Player was successfully created.' }
        format.json { render :show, status: :created, location: @player }
      else
        format.html { render :new }
        format.json { render json: @player.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /players/1
  # PATCH/PUT /players/1.json
  def update
    respond_to do |format|
      if @player.update(player_params)
        format.html { redirect_to @player, notice: 'Player was successfully updated.' }
        format.json { render :show, status: :ok, location: @player }
      else
        format.html { render :edit }
        format.json { render json: @player.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /players/1
  # DELETE /players/1.json
  def destroy
    @player.destroy
    respond_to do |format|
      format.html { redirect_to players_url, notice: 'Player was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_player
    @player = Player.find(params[:id])
  end

  def find_player
    if !params[:id].nil?
      @player = Player.find(params[:id])
    elsif !params[:user_id].nil? && !params[:game_id].nil?
      @player = Player.find_by(user_id: params[:user_id], game_id: params[:game_id])
    else
      msg = { error: 'lack of information to find player' }
      render json: msg, status: 400
      return
    end
    if @player.nil?
      msg = { error: 'player not found' }
      render json: msg, status: 400
      return
    end
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def player_params
    params.require(:player).permit(:position, :user_id, :game_id, :score)
  end
end
