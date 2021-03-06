class ZgloszeniesController < ApplicationController
  before_action :set_zgloszeny, only: [:show, :edit, :update, :destroy, :print]

  # GET /zgloszenies
  # GET /zgloszenies.json
  def index
    @zgloszenies = Zgloszenie.all
    @zgloszenies = Zgloszenie.includes(:user)
                             .where("zgloszenies.nazwa_urzadzenia ILIKE :q OR users.email ILIKE :q OR users.first_name ILIKE :q OR users.last_name ILIKE :q", q: "%#{params[:search]}%")
                             .references(:users)

    @zgloszenies = Zgloszenie.paginate(:page => params[:page], :per_page => 10)
    @user = current_user.id

    respond_to do |format|
      format.js
      format.html
      format.pdf do
        pdf = ZgloszenieListaPdf.new(@zgloszenies, @user)
        send_data pdf.render, {filename: "zgloszenia.pdf",
                              type: "application/pdf",
                              disposition: "inline"}
      end
    end
  end

  # GET /zgloszenies/1
  # GET /zgloszenies/1.json
  def show
    @zgloszenie = Zgloszenie.find(params[:id])
    respond_to do |format|
      format.html
      format.pdf do
        pdf = ZgloszenieKartaPdf.new(@zgloszenie)
        send_data pdf.render, filename: "zgloszenie_#{@zgloszenie.id}.pdf",
                              type: "application/pdf",
                              disposition: "inline"
      end
    end
  end

  def print
    @zgloszenie = Zgloszenie.find(params[:id])
  end

  # GET /zgloszenies/new
  def new
    @zgloszeny = Zgloszenie.new
  end

  # GET /zgloszenies/1/edit
  def edit
  end

  # POST /zgloszenies
  # POST /zgloszenies.json
  def create
    @zgloszeny = Zgloszenie.new(zgloszeny_params)

    respond_to do |format|
      if @zgloszeny.save
        przydzial
        CustomerNotificationMailer.started(@zgloszeny.id, @zgloszeny.user_id).deliver_later
        format.html { redirect_to @zgloszeny, notice: 'Zgłoszenie zostało pomyślnie dodane.' }
        format.json { render :show, status: :created, location: @zgloszeny }
      else
        format.html { render :new }
        format.json { render json: @zgloszeny.errors, status: :unprocessable_entity }
      end
    end
  end

  # Automatyczne przydzielanie zgloszen do najmniej zajetych praca pracownikow
  def przydzial
    @zgloszenie = Zgloszenie.find(@zgloszeny.id)
    users_list = User.where(ispracownik:true).pluck(:id)
    l = users_list.size
    i = 0
    @x = 0

    Zgloszenie.order("created_at desc").each do |zgloszeny|
      for i in users_list
        if i == zgloszeny.pracownikid
          @x += 1
          User.update(i, :praca => @x)
        end
      end
    end

    @worker = User.where(admin:false).order(:praca).pluck(:id).first
    Zgloszenie.update(@zgloszenie, :pracownikid => @worker)

  end

  def realizacja
    @zgloszenie = Zgloszenie.find(params[:id])
    zgloszenie = Zgloszenie.find(@zgloszenie.id)
    Zgloszenie.update(zgloszenie, :zrealizowane => true)
  end


  # PATCH/PUT /zgloszenies/1
  # PATCH/PUT /zgloszenies/1.json
  def update
    respond_to do |format|
      if @zgloszeny.update(zgloszeny_params.except(:user_id))
        CustomerNotificationMailer.send(@zgloszeny.status, @zgloszeny.id, @zgloszeny.user_id).deliver_later if !@zgloszeny.started?
        format.html { redirect_to @zgloszeny, notice: 'Edycja zakończyła się sukcesem.' }
        format.json { render :show, status: :ok, location: @zgloszeny }
      else
        format.html { render :edit }
        format.json { render json: @zgloszeny.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /zgloszenies/1
  # DELETE /zgloszenies/1.json
  def destroy
    @zgloszeny.destroy
    respond_to do |format|
      format.html { redirect_to zgloszenies_url, notice: 'Zgłoszenie zostało usunięte.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_zgloszeny
      @zgloszeny = Zgloszenie.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def zgloszeny_params
      params.require(:zgloszenie).permit(:dzial_id, :data_zgloszenia, :opis_uszkodzenia, :nazwa_urzadzenia, :user_id, :wysylka, :priorytet, :status, :data_naprawy, :pracownikid, :zrealizowane, :visible)
    end
end
